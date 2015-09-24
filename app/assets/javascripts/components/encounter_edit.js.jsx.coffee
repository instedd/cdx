@FlexFullRow = React.createClass
  render: ->
    `<div className="row">
      <div className="col">
        {this.props.children}
      </div>
    </div>`

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

# samples {id: Integer, entity_id: String, institution: String }
@EncounterEdit = React.createClass
  getInitialState: ->
    encounter: @props.encounter

  appendSample: (event) ->
    @setState React.addons.update(@state, {
      encounter : { samples : {
        $push : [{id: 43, entity_id: 'SDFSSD-7343', institution: 'ACME FOO Lab'}]
      }}
    })
    event.preventDefault()

  render: ->
    `<div>
      <FlexFullRow>
        <NoPatientCard />
      </FlexFullRow>
      <FlexFullRow />
      <div className="row">
        <div className="col-p1">
          <a className="side-link btn-add" href='#' onClick={this.appendSample}>+</a>
          <label>Samples</label>
        </div>
        <div className="col">
          <ul>
            {this.state.encounter.samples.map(function(sample) {
               return <Sample sample={sample}/>;
            })}
          </ul>
        </div>
      </div>
    </div>`
