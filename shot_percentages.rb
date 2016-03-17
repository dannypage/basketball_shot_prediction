#!/usr/bin/env ruby
require 'date'
require 'csv'

#def date_parse(date)
#    Date.parse(date)
#rescue => error
#    Date.parse('20071201')
#end

#END_DATE = date_parse(ARGV[0])

TEST_GAMES = 10
files = Dir[ File.join('./data', '**', '*') ].reject { |p| File.directory? p }

def percentage(tracker_hash)
    made = tracker_hash[:made]
    attempts = tracker_hash[:attempts]
    if attempts > 0
        made.to_f / attempts
    else
        0
    end
end

location = Hash.new do |hash,key|
    hash[key] = Hash.new do |hash,key|
        hash[key] = {:attempts => 0, :made => 0}
    end
end
type_and_distance = Hash.new do |hash,key|
    hash[key] = Hash.new do |hash,key|
        hash[key] = {:attempts => 0, :made => 0}
    end
end
shooter_and_type = Hash.new do |hash,key|
  hash[key] = Hash.new do |hash,key|
    hash[key] = {:attempts => 0, :made => 0}
  end
end
shot_type = Hash.new {|h, k| h[k] = {:attempts => 0, :made => 0} }
distance  = Hash.new {|h, k| h[k] = {:attempts => 0, :made => 0} }
angle     = Hash.new {|h, k| h[k] = {:attempts => 0, :made => 0} }
assisted  = Hash.new {|h, k| h[k] = {:attempts => 0, :made => 0} }
all_shots = {:attempts => 0, :made => 0}

game_counter = 0
test_game_counter = 0
testing = false
shot_counter = 0

testing_shot_type = nil
testing_distance  = nil
testing_angle     = nil
testing_assisted  = nil
testing_location  = nil
testing_all_shots = nil
testing_type_and_distance = nil
testing_shooter_and_type  = nil

brier = {
    :shot_type => 0,
    :location  => 0,
    :distance  => 0,
    :angle     => 0,
    :assisted  => 0,
    :all_shots => 0,
    :type_and_distance => 0,
    :shooter_and_type  => 0,
    :all_misses => 0,
    :all_swish  => 0,
    :coin_flips => 0
}

CSV.open("shot_results.csv","wb") do |csv|
    csv << ['games', 'shot_type', 'distance', 'location', 'angle', 'assisted', 'all_shots', 'type_and_distance', 'shooter_and_type', 'all_misses', 'all_swish', 'coin_flips']
end

files.each do |file|
    #date = Date.parse(File.basename(file).split('.')[0])
    #break if date > END_DATE
    CSV.foreach(file, headers: true) do |row|
        if row['etype'] == 'shot'
            type = row['type']
            x = row['x'].to_i
            y = row['y'].to_i
            shot_type[type][:attempts] += 1
            shot_type[type][:made] += 1 unless row['result'] == 'missed'

            location[x][y][:attempts] += 1
            location[x][y][:made] += 1 unless row['result'] == 'missed'

            length = (((x-25)**2+(y-5.25)**2)**(0.5)).round
            distance[length][:attempts] += 1
            distance[length][:made] += 1 unless row['result'] == 'missed'

            shot_angle = (Math.atan2((x-25),(y-5.25)) * 180/Math::PI).round
            angle[shot_angle][:attempts] += 1
            angle[shot_angle][:made] += 1 unless row['result'] == 'missed'

            assist = row['assist'].nil? ? false : true
            assisted[assist][:attempts] += 1
            assisted[assist][:made] += 1 unless row['result'] == 'missed'

            all_shots[:attempts] += 1
            all_shots[:made] += 1 unless row['result'] == 'missed'

            type_and_distance[type][length][:attempts] += 1
            type_and_distance[type][length][:made] += 1 unless row['result'] == 'missed'

            shooter = row['player']
            shooter_and_type[shooter][type][:attempts] += 1
            shooter_and_type[shooter][type][:made] += 1 unless row['result'] == 'missed'
        end
    end
    game_counter += 1
    if game_counter.modulo(100) == 0  && !testing
        puts game_counter
        testing           = true
        test_game_counter = 0
        shot_counter      = 0
        testing_shot_type = shot_type.clone
        testing_distance  = distance.clone
        testing_angle     = angle.clone
        testing_assisted  = assisted.clone
        testing_location  = location.clone
        testing_all_shots = all_shots.clone
        testing_type_and_distance = type_and_distance.clone
        testing_shooter_and_type  = shooter_and_type.clone
        brier[:shot_type] = 0
        brier[:distance]  = 0
        brier[:angle]     = 0
        brier[:assisted]  = 0
        brier[:location]  = 0
        brier[:all_shots] = 0
        brier[:type_and_distance] = 0
        brier[:shooter_and_type]  = 0
        brier[:all_misses] = 0
        brier[:all_swish]  = 0
        brier[:coin_flips] = 0
    elsif testing
        CSV.foreach(file, headers: true) do |row|
            if row['etype'] == 'shot'
                type = row['type']
                x = row['x'].to_i
                y = row['y'].to_i

                shot_type_percent = percentage(testing_shot_type[type])
                length = (((x-25)**2+(y-5.25)**2)**(0.5)).round
                distance_percent = percentage(testing_distance[length])

                shot_angle = (Math.atan2((x-25),(y-5.25)) * 180/Math::PI).round
                shot_angle_percent = percentage(testing_angle[shot_angle])
                assist = row['assist'] == '' ? false : true
                assisted_percent = percentage(testing_assisted[assist])
                location_percent = percentage(testing_location[x][y])
                result = row['result'] == 'missed' ? 0 : 1

                all_shot_percentage = percentage(testing_all_shots)

                type_and_distance_percentage = percentage(testing_type_and_distance[type][length])

                shooter = row['player']
                shooter_and_type_percentage = percentage(testing_shooter_and_type[shooter][type])

                brier[:shot_type] += (shot_type_percent   - result)**2
                brier[:distance]  += (distance_percent    - result)**2
                brier[:angle]     += (shot_angle_percent  - result)**2
                brier[:assisted]  += (assisted_percent    - result)**2
                brier[:location]  += (location_percent    - result)**2
                brier[:all_shots] += (all_shot_percentage - result)**2
                brier[:type_and_distance] += (type_and_distance_percentage - result)**2
                brier[:shooter_and_type] += (shooter_and_type_percentage - result)**2
                brier[:all_misses] += (0.0 - result)**2
                brier[:all_swish]  += (1.0 - result)**2
                brier[:coin_flips] += (0.5-result)**2
                shot_counter += 1
            end
        end
        test_game_counter += 1
        if test_game_counter == 10
            CSV.open("shot_results.csv","a+") do |csv|
                puts "added #{game_counter-test_game_counter} to CSV"
                csv << [game_counter-test_game_counter, brier[:shot_type]/shot_counter, brier[:distance]/shot_counter,
                        brier[:location]/shot_counter, brier[:angle]/shot_counter,
                        brier[:assisted]/shot_counter, brier[:all_shots]/shot_counter,
                        brier[:type_and_distance]/shot_counter, brier[:shooter_and_type]/shot_counter,
                        brier[:all_misses]/shot_counter, brier[:all_swish]/shot_counter,
                        brier[:coin_flips]/shot_counter]
            end
            testing = false
        end
    end
end
