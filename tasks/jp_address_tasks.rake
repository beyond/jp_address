namespace :jp_address do
  namespace :db do
    
    desc 'Create and Migrate the jp_address database.'
    task :setup => [:create, :migrate]
    
    desc 'Drops, Create and Migrate the jp_address database.'
    task :reset => [:drop, :create, :migrate]
    
    desc 'Drops and Create the jp_address database.'
    task :clear => [:drop, :create]
    
    desc 'Drops, Create and Migrate the jp_address database through HTTP (\"lha\" needed => http://sourceforge.jp/projects/lha)'
    task :reset_through_http => [:download_new_csv, :drop, :create, :migrate]
    
    desc 'Drops and recreates the jp_address database.'
    task :drop => :environment do
      drop_database(ActiveRecord::Base.configurations['jp_address'])
    end
    
    desc 'Create jp_address database.'
    task :create => :environment do
      create_database(ActiveRecord::Base.configurations['jp_address'])
    end
    
    desc 'Download new ken_all.csv (\"lha\" needed => http://sourceforge.jp/projects/lha)'
    task :download_new_csv => :environment do
      system "cd #{RAILS_ROOT}/vendor/plugins/jp_address/; rm ken_all.csv; wget -O - http://www.post.japanpost.jp/zipcode/dl/oogaki/lzh/ken_all.lzh | lha x -"
    end
    
    desc 'Insert all address data into jp_address database.'
    task :migrate => :environment do
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      ActiveRecord::Migrator.migrate("vendor/plugins/jp_address/db/migrate")
      Rake::Task["jp_address:db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
    
    namespace :schema do
      desc "Create plugins/jp_address/db/schema.rb file that can be portably used against any DB supported by AR"
      task :dump => :environment do
        require 'active_record/schema_dumper'
        File.open(ENV['SCHEMA'] || "vendor/plugins/jp_address/db/schema.rb", "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
      end
      
      desc "Load a schema.rb file into the database"
      task :load => :environment do
        file = ENV['SCHEMA'] || "vendor/plugins/jp_address/db/schema.rb"
        load(file)
      end
    end
    
    def create_database(config)
      begin
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection
      rescue
        case config['adapter']
          when 'mysql'
          @charset   = ENV['CHARSET']   || 'utf8'
          @collation = ENV['COLLATION'] || 'utf8_general_ci'
          begin
            ActiveRecord::Base.establish_connection(config.merge({'database' => nil}))
            ActiveRecord::Base.connection.create_database(config['database'], {:charset => @charset, :collation => @collation})
            ActiveRecord::Base.establish_connection(config)
          rescue
            $stderr.puts "Couldn't create database for #{config.inspect}"
          end
          when 'postgresql'
          `createdb "#{config['database']}" -E utf8`
          when 'sqlite'
          `sqlite "#{config['database']}"`
          when 'sqlite3'
          `sqlite3 "#{config['database']}"`
        end
      else
        p "#{config['database']} already exists"
      end
    end
    
    def drop_database(config)
      case config['adapter']
        when 'mysql'
        ActiveRecord::Base.connection.drop_database config['database']
        when /^sqlite/
        FileUtils.rm_f(File.join(RAILS_ROOT, config['database']))
        when 'postgresql'
        `dropdb "#{config['database']}"`
      end
    end
    
  end
end