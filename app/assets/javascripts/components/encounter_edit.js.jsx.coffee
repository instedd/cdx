@FlexFullRow = React.createClass
  render: ->
    `<div className="row">
      <div className="col">
        {this.props.children}
      </div>
    </div>`

@Modal = React.createClass
  getInitialState: ->
    show: false

  show: ->
    @setState React.addons.update(@state, {
      show: { $set: true }
    })

  hide: ->
    @setState React.addons.update(@state, {
      show: { $set: false }
    })

  hideOnOuterClick: (event) ->
    @hide() if @getDOMNode() == event.target

  handleKeyDown: (event) ->
    @hide() if event.keyCode == 27 # esc

  componentDidMount: ->
    document.addEventListener('keydown', @handleKeyDown)

  componentWillUnmount: ->
    document.removeEventListener('keydown', @handleKeyDown)

  render: ->
    return null unless @state.show
    `<div className="modal-wrapper" onClick={this.hideOnOuterClick} onKeyDown={this.handleKeyDown}>
      <div className="modal">
        {this.props.children}
      </div>
    </div>
    `

@NoPatientCard = React.createClass
  render: ->
    `<div className="card">
      <div className="card-image">
        <img src="/assets/card-unkown-cb7738feb65750667f1abf9dcbafa20f.png" alt="Card unkown" />
      </div>
      <div className="card-detail-top">
        <span>No patient information</span>
      </div>
    </div>`

@Sample = React.createClass
  render: ->
    # TODO add barcode
    # TODO add printer
    `<li>
     {this.props.sample.entity_id} ({this.props.sample.institution})
    </li>`

@TestResult = React.createClass
  render: ->
    test = this.props.test_result
    `<li>
     {test.name} ({test.device.name})
    </li>`

@AddItemSearch = React.createClass
  getInitialState: ->
    items: []

  chooseItem: (item) ->
    @props.onItemChosen(item)

  # debounce: http://stackoverflow.com/a/24679479/30948
  componentWillMount: ->
    @handleSearchDebounced = _.debounce ->
      @handleSearch.apply(@, [@state.query]);
    , 500

  onChange: (event) ->
    @setState React.addons.update(@state, {
      query: { $set: event.target.value }
    })
    @handleSearchDebounced()

  handleSearch: (query) ->
    $.ajax
      url: @props.callback,
      data:
        q: query
      success: (data) =>
        @setState React.addons.update(@state, {
          items: { $set: data }
        })

  render: ->
    templateFactory = React.createFactory(@props.itemTemplate)
    itemKey = @props.itemKey

    `<div className="item-search">
      <input type="text" placeholder="Search" onChange={this.onChange}></input>
      <ul>
        {this.state.items.map(function(item) {
          return <li key={item[itemKey]} onClick={this.chooseItem.bind(this, item)}>{templateFactory({item: item})}</li>;
        }.bind(this))}
      </ul>
     </div>`

@AddItemSearchSampleTemplate = React.createClass
  render: ->
    `<span>{this.props.item.entity_id}</span>`

# samples {id: Integer, entity_id: String, institution: String }
@EncounterEdit = React.createClass
  getInitialState: ->
    encounter: @props.encounter

  showSamplesModal: (event) ->
    @refs.samplesModal.show()
    event.preventDefault()

  appendSample: (sample) ->
    # {id: 43, entity_id: 'SDFSSD-7343', institution: 'ACME FOO Lab'}
    @setState React.addons.update(@state, {
      encounter : { samples : {
        $push : [sample]
      }}
    })
    @refs.samplesModal.hide()
    $.ajax
      url: "/encounters/#{@state.encounter.id}/samples/#{sample.id}",
      method: 'PUT'
      success: (data) =>
        if data.status == 'ok'
          @setState React.addons.update(@state, {
            encounter: { $set: data.encounter }
          })
        # TODO handle errors

  # <button onClick={this.closeSamplesModal}>Close</button>
  closeSamplesModal: (event) ->
    @refs.samplesModal.hide()
    event.preventDefault()

  render: ->
    `<div>
      <FlexFullRow>
        <NoPatientCard />
      </FlexFullRow>
      <FlexFullRow />
      <div className="row">
        <div className="col-p1">
          <a className="side-link btn-add" href='#' onClick={this.showSamplesModal}>+</a>
          <label>Samples</label>
        </div>
        <div className="col">
          <ul>
            {this.state.encounter.samples.map(function(sample) {
               return <Sample key={sample.id} sample={sample}/>;
            })}
          </ul>
        </div>
        <Modal ref="samplesModal">
          <a href="#" onClick={this.closeSamplesModal}>←</a>
          <h1>Add sample</h1>

          <AddItemSearch callback="/encounters/search_sample" onItemChosen={this.appendSample}
            itemTemplate={AddItemSearchSampleTemplate}
            itemKey="id" />
        </Modal>
      </div>

      <div className="row">
        <div className="col-p1">
          <label>Test results</label>
        </div>
        <div className="col">
          <ul>
            {this.state.encounter.test_results.map(function(test_result) {
               return <TestResult key={test_result.id} test_result={test_result}/>;
            })}
          </ul>
        </div>
      </div>
    </div>`
