require 'pageflow-public-i18n'
require 'pageflow/panorama/zip_entry_paperclip_io_adapter'

module Pageflow
  module Panorama
    class Engine < Rails::Engine
      isolate_namespace Pageflow::Panorama

      config.autoload_paths << File.join(config.root, 'lib')
      config.i18n.load_path += Dir[config.root.join('config', 'locales', '**', '*.yml').to_s]
    end
  end
end
