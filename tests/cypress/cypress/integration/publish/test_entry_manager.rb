require './bootstrap.rb'

feature 'Entry Manager', () => {
  beforeEach(function(){
    cy.auth();
    page = EntryManager.new
    page.load()
    cy.hasNoErrors()
  }

  it('displays properly when max_entries hit', () => {
    channel_json = page.create_channel({:max_entries => 1})
    channel = JSON.parse(channel_json, :symbolize_names => true)

    page.create_entries(1, channel[:channel_id])
    page.load()(filter_by_channel: channel[:channel_id])

    page.should have_no_link('New in')
    page.get('alert').text.should include "Channel limit reached"
  }

  it('offers a create option for channels with max_entries not yet reached', () => {
    channel_json = page.create_channel({:max_entries => 3})
    channel = JSON.parse(channel_json, :symbolize_names => true)

    page.create_entries(2, channel[:channel_id])
    page.load()(filter_by_channel: channel[:channel_id])

    btn_txt = 'New in ' + channel[:channel_title]
    page.should have_link(btn_txt)
  }

  it('create menu does not include channels when max_entries is hit', () => {
    channel_json = page.create_channel({:max_entries => 3})
    channel = JSON.parse(channel_json, :symbolize_names => true)

    page.create_entries(3, channel[:channel_id])
    page.load()

    page.find('.nav-create .nav-has-sub').click()
    page.all('.nav-create .nav-sub-menu a').each do |i|
      i['href'].should_not include 'admin.php.php?/cp/publish/create/' + channel[:channel_id].toString()
    }
  }

  it('edit menu goes straight to publish for max_entries 1 = 1', () => {
    channel_json = page.create_channel({:max_entries => 1})
    channel = JSON.parse(channel_json, :symbolize_names => true)

    page.create_entries(1, channel[:channel_id])
    page.load()

    page.find('.nav-edit .nav-has-sub').click()
    page.all('.nav-edit .nav-sub-menu a').each do |i|
      if i.text == channel[:channel_title]
        i['href'].should include 'admin.php?/cp/publish/edit/entry'
      }
    }
  }

  it('creates entries', () => {
    row = $db.query('SELECT count(entry_id) AS count FROM exp_channel_titles').first
    row['count'].should == 10
    page.should have(10).entry_rows

    page.create_entries
    page.load()

    row = $db.query('SELECT count(entry_id) AS count FROM exp_channel_titles').first
    row['count'].should == 20
    page.should have(20).entry_rows
  }

  it('loads a page with 100 entries', () => {
    page.create_entries(100)
    page.load()(perpage: 100)

    row = $db.query('SELECT count(entry_id) AS count FROM exp_channel_titles').first
    row['count'].should == 110
    page.should have(100).entry_rows
  }

  it('deletes a single entry', () => {
    page.should have(10).entry_rows

    page.entry_checkboxes[0].click()
    page.bulk_action.select 'Remove'
    page.action_submit_button.click()
    page.wait_for_modal_submit_button
    page.modal_submit_button.click()

    page.should have(9).entry_rows
    page.get('alert').text.should include 'The following entries were removed'
  }

  it('deletes all entries', () => {
    page.should have(10).entry_rows
    page.entry_checkboxes.each(&:click)

    page.bulk_action.select 'Remove'
    page.action_submit_button.click()
    page.wait_for_modal_submit_button
    page.modal_submit_button.click()

    page.should have(1).entry_rows
    page.entry_rows[0].text.should include 'No Entries found.'
    page.get('alert').text.should include 'The following entries were removed'
  }

  it('deletes 100 entries', () => {
    page.create_entries(100)
    page.load()(perpage: 100)

    // ... leaves the last item out of the range
    page.entry_checkboxes.each(&:click)
    page.bulk_action.select 'Remove'
    page.action_submit_button.click()
    page.wait_for_modal_submit_button
    page.modal_submit_button.click()

    page.should have(10).entry_rows
    page.get('alert').text.should include 'The following entries were removed'
    page.get('alert').text.should include 'and 96 others...'
  }

}
