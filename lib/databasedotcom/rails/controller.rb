module Databasedotcom
  module Rails
    module Controller
      module ClassMethods
        def dbdc_client
          unless @dbdc_client
            # databasedotcom-rails (hereafter dbdc-r) requires the presesence of
            # rails_root/config/databasedotcom.yml but the actual auth params 
            # can be pulled from (and in this case are) the omni-auth auth hash
            # setup as we login. This ensures that if user A logs in to org FOO
            # he/she can only see records that they have access to.
            config = {:token => session[:omniauthToken], 
              :instance_url => session[:omniauthUrl],
              :refresh_token => session[:omniauthRefresh]}
            @dbdc_client = Databasedotcom::Client.new(config)
            @dbdc_client.authenticate
          end

          @dbdc_client
        end
        
        def dbdc_client=(client)
          @dbdc_client = client
        end

        def sobject_types
          unless @sobject_types
            @sobject_types = dbdc_client.list_sobjects
          end

          @sobject_types
        end

        def const_missing(sym)
          if sobject_types.include?(sym.to_s)
            dbdc_client.materialize(sym.to_s)
          else
            super
          end
        end
      end
      
      module InstanceMethods
        def dbdc_client
          self.class.dbdc_client
        end

        def sobject_types
          self.class.sobject_types
        end
      end
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end
    end
  end
end
