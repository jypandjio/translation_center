module TranslationCenter

  # Return the default translator by building and returning the translator object
  def self.prepare_translator

    translator = TranslationCenter::CONFIG['translator_type'].camelize.constantize.where(TranslationCenter::CONFIG['identifier_type'] => TranslationCenter::CONFIG['yaml_translator_identifier']).first

    # if translator doesn't exist then create him
    if translator.blank?
      translator = TranslationCenter::CONFIG['translator_type'].camelize.constantize.new(TranslationCenter::CONFIG['identifier_type'] => TranslationCenter::CONFIG['yaml_translator_identifier'])
      begin
        translator.save(validate: false)
      rescue
        translator = nil
      end
    end
    translator
  end

  def self.included(base)
    base.class_eval do
      if TranslationCenter::CONFIG['i18n_source']  == 'db'
        alias_method_chain :load_translations, :db
      end
    end
  end

  # wraps a span if inspector option is set to all
  def wrap_span(translation, translation_key)
    # put the inspector class if inspector is all and the key doesn't belongs to translation_center
    if TranslationCenter::CONFIG['inspector'] == 'all' && translation_key.name.to_s.split('.').first != 'translation_center'
      "<span class='tc-inspector-key' data-type='#{translation_key.status(I18n.locale)}' data-id='#{translation_key.id}'> #{translation} </span>".html_safe
    else
      translation
    end
  end

  def load_translations_with_db
    load_file_with_db
    rb_files = I18n.load_path.select{|filename| File.extname(filename).tr('.', '').downcase == 'rb'}
    rb_files.each {|file| load_file(file)}
  end

  def load_file_with_db
    data = {}
    translations = TranslationCenter::Translation.select('name, value, lang').joins(:translation_key).where(status: "accepted")
    translations.each do |translation|
      t = [translation.lang, translation.name.split(".")].flatten.reverse
      value = {t.shift => translation.value}
      values = t.inject(value) {|hash, k| {k => hash}}
      data.deep_merge!(values)
    end
    data.each { |locale, d| store_translations(locale, d || {}) }
  end

  # load tha translation config
  if FileTest.exists?("config/translation_center.yml")
    TranslationCenter::CONFIG = YAML.load_file("config/translation_center.yml")[Rails.env]
    # identifier is by default email
    TranslationCenter::CONFIG['identifier_type'] ||= 'email'
    TranslationCenter::CONFIG['translator_type'] ||= 'User'
  else
    puts "WARNING: translation_center will be using default options if config/translation_center.yml doesn't exists"
    TranslationCenter::CONFIG = {'enabled' => true, 'inspector' => 'all', 'lang' => {'en' => {'name' => 'English', 'direction' => 'ltr'}, 'nl' => {'name' => 'Dutch', 'direction' => 'ltr'}}, 'yaml_translator_identifier' => 'coder@tc.com', 'i18n_source' => 'db', 'yaml2db_translations_accepted' => true,
                                'accept_admin_translations' => true,  'save_default_translation' => true, 'identifier_type' => 'email', 'translator_type' => 'User' }
  end
  I18n.available_locales = TranslationCenter::CONFIG['lang'].keys

end

module I18n
  class ExceptionHandler
    def call(exception, locale, key, options)
      if exception.is_a?(MissingTranslation)
        if TranslationCenter::CONFIG['enabled'] && ActiveRecord::Base.connection.table_exists?('translation_center_translation_keys')
          key_names = exception.keys
          key_names.shift
          key_name_string = key_names.join(".")
          translation_key = TranslationCenter::TranslationKey.find_or_create_by_name(key_name_string)
          translation_key.create_default_translation if TranslationCenter::CONFIG['save_default_translation'] && translation_key.translations.in(:en).empty?
        end
      end
      super
    end
  end

  # override html_message to add a class to the returned span
  class MissingTranslation
    module Base
      # added another class to be used
      def html_message
        category = keys.first
        key = keys.last.to_s.gsub('_', ' ').gsub(/\b('?[a-z])/) { $1.capitalize }
        translation_key = keys
        # remove locale
        # translation_key.shift

        translation_key = TranslationCenter::TranslationKey.find_by_name(translation_key.join('.'))
        # don't put the inspector class if inspector is off or the key belongs to translation_center
        if TranslationCenter::CONFIG['inspector'] == 'off' || category == 'translation_center'
          %(<span class="translation_missing" title="translation missing: #{keys.join('.')}">#{key}</span>)
        else
          %(<span class="translation_missing tc-inspector-key" data-type="#{translation_key.status(I18n.locale)}" data-id="#{translation_key.id}" title="translation missing: #{keys.join('.')}">#{key}</span>)
        end
      end

    end
  end
end

I18n::Backend::Base.send :include, TranslationCenter



