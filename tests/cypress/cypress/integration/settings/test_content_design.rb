require './bootstrap.rb'

context('Content & Design Settings', () => {

  beforeEach(function() {
    cy.auth();
    page = ContentDesign.new
    page.load()
    cy.hasNoErrors()
  }

  it('shows the Content & Design Settings page', () => {
    page.all_there?.should == true
  }

  it('should load current settings into form fields', () => {
    new_posts_clear_caches = eeConfig({item: 'new_posts_clear_caches')
    enable_sql_caching = eeConfig({item: 'enable_sql_caching')
    auto_assign_cat_parents = eeConfig({item: 'auto_assign_cat_parents')
    enable_emoticons = eeConfig({item: 'enable_emoticons')

    page.new_posts_clear_caches.value.should == new_posts_clear_caches
    page.enable_sql_caching.value.should == enable_sql_caching
    page.auto_assign_cat_parents.value.should == auto_assign_cat_parents
    page.image_resize_protocol.has_checked_radio(eeConfig({item: 'image_resize_protocol')).should == true
    page.image_library_path.value.should == eeConfig({item: 'image_library_path')
    page.thumbnail_suffix.value.should == eeConfig({item: 'thumbnail_prefix')
    page.enable_emoticons.value.should == enable_emoticons
    page.emoticon_url.value.should == eeConfig({item: 'emoticon_url')
  }

  context('when validating the form', () => {
    let(:image_library_path_error) { 'This field must contain a valid path to an image processing library if ImageMagick or NetPBM is the selected protocol.' }

    it('validates image resize protocol when using ImageMagick', () => {
      // Should only show an error for image library path if ImageMagick or NetPBM are selected
      page.image_resize_protocol.choose_radio_option('imagemagick')
      page.image_library_path.clear().type(''
      page.image_library_path.blur()
      page.wait_for_error_message_count(1)
      should_have_form_errors(page)
      should_have_error_text(page.image_library_path, image_library_path_error)
    }

    it('validates image resize protocol when using NetPBM', () => {
      page.image_resize_protocol.choose_radio_option('netpbm')
      page.image_library_path.clear().type(''
      page.image_library_path.blur()
      page.wait_for_error_message_count(1, 10)
      should_have_form_errors(page)
      should_have_error_text(page.image_library_path, image_library_path_error)
    }

    it('validates a nonsense image library path', () => {
      page.image_resize_protocol.choose_radio_option('netpbm')
      page.image_library_path.clear().type('dfsdf'
      page.image_library_path.blur()
      page.wait_for_error_message_count(1)
      should_have_form_errors(page)
      should_have_error_text(page.image_library_path, $invalid_path)
    }

    it('validates a valid set of library and path', () => {
      page.image_resize_protocol.choose_radio_option('gd')
      page.image_library_path.clear().type(''
      page.image_library_path.blur()
      page.wait_for_error_message_count(0)
      should_have_no_form_errors(page)
      should_have_no_error_text(page.image_library_path)
    }
  }

  it('should reject XSS', () => {
    page.image_library_path.set $xss_vector
    page.image_library_path.blur()
    page.wait_for_error_message_count(1)
    should_have_error_text(page.image_library_path, $xss_error)
    should_have_form_errors(page)

    page.thumbnail_suffix.set $xss_vector
    page.thumbnail_suffix.blur()
    page.wait_for_error_message_count(2)
    should_have_error_text(page.thumbnail_suffix, $xss_error)
    should_have_form_errors(page)

    page.emoticon_url.set $xss_vector
    page.emoticon_url.blur()
    page.wait_for_error_message_count(3)
    should_have_error_text(page.emoticon_url, $xss_error)
    should_have_form_errors(page)
  }

  it('should save and load the settings', () => {
    new_posts_clear_caches = eeConfig({item: 'new_posts_clear_caches')
    enable_sql_caching = eeConfig({item: 'enable_sql_caching')
    auto_assign_cat_parents = eeConfig({item: 'auto_assign_cat_parents')
    enable_emoticons = eeConfig({item: 'enable_emoticons')

    page.new_posts_clear_caches_toggle.click()
    page.enable_sql_caching_toggle.click()
    page.auto_assign_cat_parents_toggle.click()
    page.image_resize_protocol.choose_radio_option('imagemagick')
    page.image_library_path.clear().type('/'
    page.thumbnail_suffix.clear().type('mysuffix'
    page.enable_emoticons_toggle.click()
    // Don't test this, we manually override this path in config.php for the tests
    #page.emoticon_url.clear().type('http://myemoticons/'
    page.submit

    page.get('wrap').contains('Preferences updated'
    page.new_posts_clear_caches.value.should_not == new_posts_clear_caches
    page.enable_sql_caching.value.should_not == enable_sql_caching
    page.auto_assign_cat_parents.value.should_not == auto_assign_cat_parents
    page.image_resize_protocol.has_checked_radio('imagemagick').should == true
    page.image_library_path.value.should == '/'
    page.thumbnail_suffix.value.should == 'mysuffix'
    page.enable_emoticons.value.should_not == enable_emoticons
    #page.emoticon_url.value.should == 'http://myemoticons/'
  }
}
