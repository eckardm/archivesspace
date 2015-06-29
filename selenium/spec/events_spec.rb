require_relative 'spec_helper'


describe "Events" do

  before(:all) do
    backend_login

    @repo = create(:repo, :repo_code => "events_test_#{Time.now.to_i}")
    set_repo(@repo.uri)

    (@archivist_user, @archivist_pass) = create_user
    add_user_to_archivists(@archivist_user, @repo.uri)

    @accession = create(:accession, :title => "Events link to this accession")
    agent_uri, @agent_name = create_agent("Geddy Lee")
    run_index_round

    login(@archivist_user, @archivist_pass)
    select_repo(@repo.repo_code)
  end


  after(:all) do
    logout
  end


  it "creates an event and links it to an agent and an agent as a source" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Event").click
    $driver.find_element(:id, "event_event_type_").select_option('accession')
    $driver.find_element(:id, "event_outcome_").select_option("pass")
    $driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's another lie: all test subjects perished.")

    $driver.find_element(:id, "event_date__date_type_").select_option("single")
    $driver.clear_and_send_keys([:id, "event_date__begin_"], ["1776", :tab])

    agent_subform = $driver.find_element(:id, "event_linked_agents__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    $driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')

    token_input = agent_subform.find_element(:id, "token-input-event_linked_agents__0__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys("Admin")
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:id, "event_linked_records__0__role_").select_option('source')

    record_subform = $driver.find_element(:id, "event_linked_records__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys("Geddy")
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:css => "form#new_event button[type='submit']").click

    # Success!
    assert(5) {
      $driver.find_element_with_text('//div', /Event Created/).should_not be_nil
    }
    run_all_indexers

    expect {
      assert(10) {
        $driver.find_element(:link, "Browse").click
        $driver.find_element(:link, "Agents").click

        $driver.clear_and_send_keys([:css, ".sidebar input.text-filter-field"], "Geddy*" )
        $driver.find_element(:css, ".sidebar input.text-filter-field + div button").click
        $driver.find_element_with_text('//tr', /Geddy/).find_element(:link, 'View').click
    
        $driver.find_element_with_text('//td', /accession/)
      }
    }.not_to raise_error

  end

  it "creates an event and links it to an agent and accession" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Event").click
    $driver.find_element(:id, "event_event_type_").select_option('virus_check')
    $driver.find_element(:id, "event_outcome_").select_option("pass")
    $driver.clear_and_send_keys([:id, "event_outcome_note_"], "OK, that's a lie: all test subjects perished.")

    $driver.find_element(:id, "event_date__date_type_").select_option("single")
    $driver.clear_and_send_keys([:id, "event_date__begin_"], ["2000-01-01", :tab])

    agent_subform = $driver.find_element(:id, "event_linked_agents__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    $driver.find_element(:id, "event_linked_agents__0__role_").select_option('recipient')

    token_input = agent_subform.find_element(:id, "token-input-event_linked_agents__0__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys("Geddy")
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:id, "event_linked_records__0__role_").select_option('source')

    record_subform = $driver.find_element(:id, "event_linked_records__0__role_").
      nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    token_input = record_subform.find_element(:id, "token-input-event_linked_records__0__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys(@accession.title)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:css => "form#new_event button[type='submit']").click

    # Success!
    assert(5) {
      $driver.find_element_with_text('//div', /Event Created/).should_not be_nil
    }
  end

  it "can add an external document to an Event" do
    $driver.find_element(:css => '#event_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click
    $driver.clear_and_send_keys([:id, "event_external_documents__0__title_"], "My URI document")
    $driver.clear_and_send_keys([:id, "event_external_documents__0__location_"], "http://archivesspace.org")

    $driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")

    # check external documents
    external_document_sections = $driver.blocking_find_elements(:css => '#event_external_documents_ .subrecord-form-wrapper')
    external_document_sections.length.should eq (1)
    external_document_sections[0].find_element(:link => "http://archivesspace.org")
  end


  it "should be searchable" do
    run_index_round
    $driver.find_element(:id, 'global-search-button').click
    $driver.find_element(:link, "Event").click
    assert(5) { $driver.find_element_with_text("//h2", /Search Results/) }
  end

end

