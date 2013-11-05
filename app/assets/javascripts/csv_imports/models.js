angular.module('Directory.csvImports.models', ['RailsModel'])
.factory('CsvImport', ['Model', 'Schema', function (Model, Schema) {
  var CsvImport = Model({url:'/api/csv_imports', name: 'csv_import', only: ['mappingsAttributes', 'collectionId', 'commit']});

  CsvImport.prototype.editButtonMessage = function () {
    return this.state == 'imported' ? 'Edit' : 'Continue';
  };

  CsvImport.prototype.cancel = function () {
    var $this = this;
    this.commit = 'cancel';
    // console.log(this);
    this.update().then(function(){ $this.state = "cancelled" });
  };

  CsvImport.prototype.resetMappingToExtra = function (index) {
    this.mappings[index].column = Schema.columnize(this.headers[index]);
    this.mappings[index].type =   '*';
  };

  CsvImport.prototype.terminal = function () {
    return (this.state == "cancelled" || this.state == "imported");
  }

  CsvImport.prototype.link = function () {
    if (this.terminal() || this.unActionable()) {
      return; 
    }
    return "/imports/" + this.id;
  }

  CsvImport.prototype.importable = function () {
    return !(this.isSaving || (this.state != "analyzed"));
  }

  CsvImport.prototype.unActionable = function () {
    return (this.state.match(/^queued/) || this.state == 'analyzing' || this.state == 'importing');
  }

  // CsvImport.attrAccessible = ['mappingsAttributes', 'collectionId', 'commit'];

  CsvImport.prototype.alertSync = function () {
    return {
      'promise': [CsvImport, CsvImport.get, this.id],
      'state':{
        'analyzing':     {status: 'Analyzing', progress: 50},
        'analyzed':      {status: 'Analyzed',  progress: 100, done: true, path: '/imports/:id' },
        'error':         {status: 'Error',     progress: undefined, done: true, path: '/imports/:id' },
        'queued_import': {status: 'Waiting',   progress: 10},
        'importing':     {status: 'Importing', progress: 30},
        'imported':      {status: 'Imported',  progress: 100, done: true, path: '/collections/:id' }
      }
    }
  };

  return CsvImport;
}])
.factory('MappingSet', [function() {
  function MappingSet() {
    this.mappingAsHash = {};
    this.mappingAsArry = [];
  }

  MappingSet.prototype = {
    setByIndex: function(index, name) {
      if (typeof index !== 'undefined' && name) {
        // Check to see if we have any problems:
        var problems = [];
        normalizeParams(this.mappingAsHash, name, index, problems);
        while (problems.length > 0) {
          this.mappingAsArry[problems.pop()] = undefined;
        }
        
        // Then reapply the whole thing.
        this.mappingAsHash = {};
        // Set the new value.
        this.mappingAsArry[index] = name;

        for (var i=0; i<this.mappingAsArry.length; i++) {
          normalizeParams(this.mappingAsHash, this.mappingAsArry[i], i, problems);
        }
      }
    },
    setByName:  function(name, index) {
      return this.setByIndex(index, name);
    },
    set: function(index, name) {
      return this.setByIndex(index, name);
    }
  }

  return MappingSet;
}])
.factory('Schema', [function () {

  var schema = {columns: [], types: [{humanName: '---', name: '*'}], get: function () { return schema }};

  function camelize(key) {
    if (!angular.isString(key)) {
      return key;
    }

    // should this match more than word and digit characters?
    return key.replace(/_[\w\d]/g, function (match, index, string) {
      return index === 0 ? match : string.charAt(index + 1).toUpperCase();
    });
  }

  schema.typesByName = {
    string:      "Title / Label",
    short_text:  "Short Text",
    text:        "Longform Text",
    date:        "Date",
    number:      "Number",
    array:       "Comma Separated List",
    person:      "Person's Name",
    geolocation: "Geographic Location",
  };

  angular.forEach(schema.typesByName, function (humanName, name) {
    schema.types.push({humanName: humanName, name: name});
  });

  schema.columnize = function stringToColumnName(name) {
    if (typeof name !== 'undefined' && name != null) {
      return 'extra[' + escape(name.toLowerCase().replace(/\W+/g,'_')) + ']';
    }
  }

  angular.forEach({
    "title":                           {type:"string",      display: "Title"},
    "episode_title":                   {type:"string",      display: "Episode Title"},
    "series_title":                    {type:"string",      display: "Series Title"},
    "description":                     {type:"text",        display: "Description"},
    "identifier":                      {type:"string",      display: "Item ID"},
    "date_broadcast":                  {type:"date",        display: "Date Broadcast"},
    "date_created":                    {type:"date",        display: "Date Created"},
    "rights":                          {type:"text",        display: "Rights"},
    "physical_format":                 {type:"short_text",  display: "Physical Format"},
    "digital_format":                  {type:"short_text",  display: "Digital Format"},
    "physical_location":               {type:"short_text",  display: "Physical Location"},
    "audio_files[][remote_file_url]":  {type:"array",       display: "Links(s) to Audio File"},
    "duration":                        {type:"number",      display: "Duration"},
    "music_sound_used":                {type:"short_text",  display: "Music"},
    "date_peg":                        {type:"short_text",  display: "Date Peg"},
    "tags":                            {type:"array",       display: "Tags"},
    "geographic_location":             {type:"geolocation", display: "Geolocation"},
    "notes":                           {type:"text",        display: "Notes"},
    "interviewers[]":                  {type:"person",      display: "Interviewer"},
    "interviewees[]":                  {type:"person",      display: "Interviewee"},
    "producers[]":                     {type:"person",      display: "Producer"},
    "creators[]":                      {type:"person",      display: "Creator"},
    "hosts[]":                         {type:"person",      display: "Host"}
  }, function (metaData, columnName) {
    for (var typeIndex=0; schema.types[typeIndex].name != metaData.type; typeIndex++);
    schema.columns.push({name:columnName, humanName:metaData.display, typeId: typeIndex, camelCaseName:camelize(columnName), typeName:metaData.type});
  });

  schema.appendColumns = function (thingsToAdd) {
    var clone = schema.columns.slice(0, this.columns.length);

    thingsToAdd.splice(0,0,0,0);
    clone.splice.apply(clone, thingsToAdd);
    return clone;
  };

  schema.columnsWith = function () {
    var columnNames = Array.prototype.slice.call(arguments, 0, arguments.length),
        columns = [];

    for (index in columnNames) {
      columns.push(schema.nameToColumn(columnNames[index]));
    }

    return schema.appendColumns(columns);
  };

  schema.nameToColumn = function (name) {
    return {humanName: "Extra: " + name, name: schema.columnize(name)};
  }

  schema.columnByName = function (columnName) {
    for (var i=0; i < schema.columns.length; i++) {
      if (columnName == schema.columns[i].name) {
        return schema.columns[i];
      }
    }
    return undefined;
  };

  schema.types.get = function (index) {
    return schema.types[index];
  }

  schema.getValue = function (column, mappings, row) {
    var i = schema.isMapped(column, mappings);
    if (i !== false) {
      return row[i];
    } else  {
      return undefined;
    }
  }

  schema.isMapped = function (column, mappings) {
    if (!mappings || !column) return false;
    for (var i=0; i < mappings.length; i++) {
      var colName = (column.name || column);
      if (mappings[i].column == colName) { return i }
    }
    return false;
  }

  schema.includesExtraFields = function(mapping) {
    if (!mapping) return false;
    for (var i=0; i < mapping.length; i++) {
      var match = false;
      angular.forEach(schema.columns, function (column) {
        if (column.name == mapping[i].column) {
          match = true;
        }
      });
      if (!match) {
        return true;
      }
    }
    return false;
  }

  return schema;
}]);
