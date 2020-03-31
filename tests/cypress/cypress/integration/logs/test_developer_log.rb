require './bootstrap.rb'

def confirm (page)
  page.displayed?
  page.heading.text.should eq 'Developer Logs'
  page.should have_keyword_search
  page.should have_submit_button
  page.should have_date_filter
  page.should have_perpage_filter
}

feature 'Developer Log', () => {

  beforeEach(function() {
    cy.auth();

    page = DeveloperLog.new
  }

  // This will confirm filters
  it('shows the Developer Logs page', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.should have_remove_all
    page.should have_pagination

    page.perpage_filter.text.should eq "show (25)"

    page.should have(6).pages
    page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]

    page.should have(25).items // Default is 25 per page
  }

  // Confirming phrase search
  it('searches by phrases', () => {
    our_desc = "Rspec entry for search"

    page.generate_data(count: 1, timestamp_max: 0, description: our_desc)
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    // Be sane and make sure it's there before we search for it
    page.get('wrap').contains(our_desc

    page.keyword_search.clear().type("Rspec"
    page.keyword_search.send_keys(:enter)

    page.heading.text.should eq 'Search Results we found 1 results for "Rspec"'
    page.keyword_search.value.should eq "Rspec"
    page.get('wrap').contains(our_desc
    page.should have(1).items
  }

  it('searches localized deprecation strings', () => {
    our_phrase = "called in"

    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    // Be sane and make sure it's there before we search for it
    page.get('wrap').contains(our_phrase

    page.keyword_search.set our_phrase
    page.keyword_search.send_keys(:enter)

    page.get('wrap').contains(our_phrase
    page.should_not have_no_results
  }

  it('shows no results on a failed search', () => {
    our_desc = "NotFoundHere"

    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.keyword_search.set our_desc
    page.keyword_search.send_keys(:enter)

    page.heading.text.should eq 'Search Results we found 0 results for "' + our_desc + '"'
    page.keyword_search.value.should eq our_desc
    page.get('wrap').contains(our_desc
    page.should have_date_filter
    page.should have_perpage_filter

    page.get('no_results').should('exist')

    page.should_not have_pagination
    page.should_not have_remove_all
  }

  it('filters by date', () => {
    page.generate_data(count: 19, timestamp_max: 22)
    page.generate_data(count: 42, timestamp_min: 36, timestamp_max: 60)
    page.load()
    cy.hasNoErrors()

    confirm page

    page.should have(25).items // Default is 25 per page

    page.date_filter.click()
    page.wait_until_date_filter_menu_visible
    page.date_filter_menu.click_link "Last 24 Hours"

    page.date_filter.text.should eq "date (Last 24 Hours)"
    page.should have(19).items
    page.should_not have_pagination
  }

  it('can change page size', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.perpage_filter.click()
    page.wait_until_perpage_filter_menu_visible
    page.perpage_filter_menu.click_link "25 results"

    page.perpage_filter.text.should eq "show (25)"
    page.should have(25).items
    page.should have_pagination
    page.should have(6).pages
    page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
  }

  it('can set a custom limit', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.perpage_filter.click()
    page.wait_until_perpage_manual_filter_visible
    page.perpage_manual_filter.clear().type("42"
    page.execute_script("$('div.filters a[data-filter-label^=show] + div.sub-menu input[type=text]').parents('form').submit()")

    page.perpage_filter.text.should eq "show (42)"
    page.should have(42).items
    page.should have_pagination
    page.should have(6).pages
    page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
  }

  // Confirming combining filters work
  it('can combine date and page size filters', () => {
    page.generate_data(count: 23, timestamp_max: 22)
    page.generate_data(count: 42, timestamp_min: 36, timestamp_max: 60)
    page.load()
    cy.hasNoErrors()

    confirm page

    page.perpage_filter.click()
    page.wait_until_perpage_filter_menu_visible
    page.perpage_filter_menu.click_link "25"
    cy.hasNoErrors()

    page.perpage_filter.text.should eq "show (25)"
    page.should have(25).items
    page.should have_pagination

    page.date_filter.click()
    page.wait_until_date_filter_menu_visible
    page.date_filter_menu.click_link "Last 24 Hours"

    page.perpage_filter.text.should eq "show (25)"
    page.date_filter.text.should eq "date (Last 24 Hours)"
    page.should have(23).items
    page.should_not have_pagination
  }

  it('can combine phrase search with filters', () => {
    our_desc = "Rspec entry for search"
    page.generate_data(count: 18, timestamp_max: 22)
    page.generate_data(count: 5, timestamp_max: 22, description: our_desc)
    page.generate_data(count: 42, timestamp_min: 36, timestamp_max: 60)
    page.generate_data(count: 10, timestamp_min: 36, timestamp_max: 60, description: our_desc)
    page.load()
    cy.hasNoErrors()

    confirm page

    page.date_filter.click()
    page.wait_until_date_filter_menu_visible
    page.date_filter_menu.click_link "Last 24 Hours"
    cy.hasNoErrors()

    page.keyword_search.clear().type("Rspec"
    page.keyword_search.send_keys(:enter)

    page.date_filter.text.should eq "date (Last 24 Hours)"
    page.heading.text.should eq 'Search Results we found 5 results for "Rspec"'
    page.keyword_search.value.should eq "Rspec"
    page.get('wrap').contains(our_desc
    page.should have(5).items
    page.should_not have_pagination
  }

  // Confirming the log deletion action
  it('can remove a single entry', () => {
    our_desc = "Rspec entry to be deleted"

    page.generate_data
    page.generate_data(count: 1, timestamp_max: 0, description: our_desc)
    page.load()
    cy.hasNoErrors()

    confirm page

    log = page.find('section.item-wrap div.item', :text => our_desc)
    log.find('li.remove a').click() // Activates a modal

    page.wait_until_modal_visible
    page.modal_title.text.should eq "Confirm Removal"
    page.modal.text.should include "You are attempting to remove the following items, please confirm this action."
    page.modal.text.should include our_desc
    page.modal_submit_button.click() // Submits a form

    page.should have_alert
    page.get('alert').text.should eq "Logs Deleted 1 log(s) deleted from Developer logs"

    page.should have_no_content our_desc
  }

  it('can remove all entries', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.remove_all.click() // Activates a modal

    page.wait_until_modal_visible
    page.modal_title.text.should eq "Confirm Removal"
    page.modal.text.should include "You are attempting to remove the following items, please confirm this action."
    page.modal.text.should include "Developer Logs: All"
    page.modal_submit_button.click() // Submits a form

    page.should have_alert
    page.get('alert').text.should eq "Logs Deleted 250 log(s) deleted from Developer logs"

    page.get('no_results').should('exist')
    page.should_not have_pagination
  }

  // Confirming Pagination behavior
  it('shows the Prev button when on page 2', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    click_link "Next"

    page.should have_pagination
    page.should have(7).pages
    page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
  }

  it('does not show Next on the last page', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    click_link "Last"

    page.should have_pagination
    page.should have(6).pages
    page.pages.map {|name| name.text}.should == ["First", "Previous", "8", "9", "10", "Last"]
  }

  it('does not lose a filter value when paginating', () => {
    page.generate_data
    page.load()
    cy.hasNoErrors()

    confirm page

    page.perpage_filter.click()
    page.wait_until_perpage_filter_menu_visible
    page.perpage_filter_menu.click_link "25 results"
    cy.hasNoErrors()

    page.perpage_filter.text.should eq "show (25)"
    page.should have(25).items

    click_link "Next"

    page.perpage_filter.text.should eq "show (25)"
    page.should have(25).items
    page.should have_pagination
    page.should have(7).pages
    page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
  }

  it('will paginate phrase search results', () => {
    page.generate_data(count:35, description: "Hidden entry")
    page.generate_data(count:35, description: "Visible entry")
    page.load()
    cy.hasNoErrors()

    confirm page

    page.perpage_filter.click()
    page.wait_until_perpage_filter_menu_visible
    page.perpage_filter_menu.click_link "25"
    cy.hasNoErrors()

    page.keyword_search.clear().type("Visible"
    page.keyword_search.send_keys(:enter)
    cy.hasNoErrors()

    // Page 1
    page.heading.text.should eq 'Search Results we found 35 results for "Visible"'
    page.keyword_search.value.should eq "Visible"
    page.items.should_not have_text "Hidden"
    page.perpage_filter.text.should eq "show (25)"
    page.should have(25).items
    page.should have_pagination
    page.should have(5).pages
    page.pages.map {|name| name.text}.should == ["First", "1", "2", "Next", "Last"]

    click_link "Next"

    // Page 2
    page.heading.text.should eq 'Search Results we found 35 results for "Visible"'
    page.keyword_search.value.should eq "Visible"
    page.items.should_not have_text "Hidden"
    page.perpage_filter.text.should eq "show (25)"
    page.should have(10).items
    page.should have_pagination
    page.should have(5).pages
    page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "Last"]
  }

}
