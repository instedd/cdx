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

@SimpleItem = React.createClass
  render: ->
    return `<li>{this.props.data}</li>`


@Sample = React.createClass
  render: ->
    # TODO add barcode
    # TODO add printer
    `<li key={this.props.sample.id}>
     {this.props.sample.entity_id} ({this.props.sample.institution})
    </li>`

@AddItemSearch = React.createClass
  chooseItem: (item) ->
    @props.onItemChosen(item)

  render: ->
    items = [
      {id: 43, entity_id: 'SDFSSD-7343', institution: 'ACME FOO Lab'},
      {id: 44, entity_id: 'SDFSSD-7344', institution: 'ACME FOO Lab'},
      {id: 45, entity_id: 'SDFSSD-7345', institution: 'Umbrella'}
    ]
    templateFactory = React.createFactory(@props.itemTemplate)
    itemKey = @props.itemKey

    `<div className="item-search">
      <input type="text"></input>
      <ul>
        {items.map(function(item) {
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

          <AddItemSearch callback="/foo" onItemChosen={this.appendSample}
            itemTemplate={AddItemSearchSampleTemplate}
            itemKey="id" />
        </Modal>
      </div>
    </div>`
