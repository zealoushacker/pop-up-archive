angular.module('Directory.items.models', ['RailsModel', 'Directory.audioFiles.models'])
.factory('Item', ['Model', '$http', '$q', 'Contribution', 'Person', 'AudioFile', 'Player', function (Model, $http, $q, Contribution, Person, AudioFile, Player) {

  var attrAccessible = "dateBroadcast dateCreated datePeg description digitalFormat digitalLocation episodeTitle identifier language musicSoundUsed notes physicalFormat physicalLocation rights seriesTitle tags title transcription adoptToCollection tagList text id".split(' ');

  var Item = Model({url:'/api/collections/{{collectionId}}/items/{{id}}', name: 'item', only: attrAccessible});

  Item.beforeRequest(function(data, resource) {

    var dataList = [];
    if (angular.isArray(data)) {
      dataList = data;
    } else {
      dataList = [data];
    }

    angular.forEach(dataList, function(value, key){

      value.tags = [];
      angular.forEach((value.tag_list || []), function (v,k) {
        value.tags.push(v['text']);
      });
      delete value.tag_list;

      if ((!value.id || parseInt(value.id, 10) <= 0) || (value.adoptToCollection == value.collectionId)) {
        delete value.adoptToCollection;
      }

      // console.log("item value:", value);

      if (value.language) {
        value.language = value.language.id;
      }

    });

    return data;
  });

  Item.beforeResponse(function(data, resource) {

    data.tagList = [];
    angular.forEach((data.tags || []), function (v,k) {
      data.tagList.push({id:v, text:v});
    });

    data.language = {id: data.language, text: Item.languageLookup[data.language]};

    if (data.id) {
      data.adoptToCollection = data.collectionId;
    }

    return data;
  });

  Item._setLanguageLookup = function(langs) {
    var lookup = {};
    for(var i in langs) {
      if (langs[i].id && langs[i].text) {
        lookup[langs[i].id] = langs[i].text;
      }
      if (langs[i].children) {
        var children = langs[i].children;
        for(var ci in children) {
          lookup[children[ci].id] = children[ci].text;
        }
      }
    }
    return lookup;
  };

  Item.languages = [{"text":"Common","children":[{"id":"en-US","text":"English (United States)"},{"id":"ar-EG","text":"Arabic (Egypt)"},{"id":"zh-CN","text":"Chinese (China)"},{"id":"fr-FR","text":"French"},{"id":"de-DE","text":"German"},{"id":"it-IT","text":"Italian"},{"id":"ja-JA","text":"Japanese"},{"id":"ko-KO","text":"Korean"},{"id":"pt-PT","text":"Portuguese"},{"id":"ru-RU","text":"Russian"},{"id":"es-ES","text":"Spanish (Spain)"}]},{"text":"Afrikaans","children":[{"id":"af-NA","text":"Afrikaans (Namibia)"},{"id":"af-ZA","text":"Afrikaans (South Africa)"}]},{"text":"Arabic","children":[{"id":"ar-AE","text":"Arabic (United Arab Emirates)"},{"id":"ar-BH","text":"Arabic (Bahrain)"},{"id":"ar-DJ","text":"Arabic (Djibouti)"},{"id":"ar-DZ","text":"Arabic (Algeria)"},{"id":"ar-EG","text":"Arabic (Egypt)"},{"id":"ar-ER","text":"Arabic (Eritrea)"},{"id":"ar-IL","text":"Arabic (Israel)"},{"id":"ar-IQ","text":"Arabic (Iraq)"},{"id":"ar-JO","text":"Arabic (Jordan)"},{"id":"ar-KM","text":"Arabic (Comoros)"},{"id":"ar-KW","text":"Arabic (Kuwait)"},{"id":"ar-LB","text":"Arabic (Lebanon)"},{"id":"ar-LY","text":"Arabic (Libya)"},{"id":"ar-MA","text":"Arabic (Morocco)"},{"id":"ar-MR","text":"Arabic (Mauritania)"},{"id":"ar-OM","text":"Arabic (Oman)"},{"id":"ar-QA","text":"Arabic (Qatar)"},{"id":"ar-SA","text":"Arabic (Saudi Arabia)"},{"id":"ar-SD","text":"Arabic (Sudan)"},{"id":"ar-SO","text":"Arabic (Somalia)"},{"id":"ar-SY","text":"Arabic (Syrian Arab Republic)"},{"id":"ar-TD","text":"Arabic (Chad)"},{"id":"ar-TN","text":"Arabic (Tunisia)"},{"id":"ar-YE","text":"Arabic (Yemen)"}]},{"id":"bn-BD","text":"Bengali (Bangladesh)"},{"id":"bo","text":"Tibetan"},{"id":"bg-BG","text":"Bulgarian (Bulgaria)"},{"id":"ca-AD","text":"Catalan (Andorra)"},{"id":"cs-CZ","text":"Czech (Czech Republic)"},{"id":"cy","text":"Welsh"},{"id":"da-DK","text":"Danish (Denmark)"},{"text":"German","children":[{"id":"de-AT","text":"German (Austria)"},{"id":"de-BE","text":"German (Belgium)"},{"id":"de-CH","text":"German (Switzerland)"},{"id":"de-DE","text":"German (Germany)"},{"id":"de-LI","text":"German (Liechtenstein)"},{"id":"de-LU","text":"German (Luxembourg)"}]},{"text":"Modern Greek (1453-)","children":[{"id":"el-CY","text":"Modern Greek (1453-) (Cyprus)"},{"id":"el-GR","text":"Modern Greek (1453-) (Greece)"}]},{"text":"English","children":[{"id":"en-AG","text":"English (Antigua and Barbuda)"},{"id":"en-AI","text":"English (Anguilla)"},{"id":"en-AN","text":"English (Netherlands Antilles)"},{"id":"en-AS","text":"English (American Samoa)"},{"id":"en-AU","text":"English (Australia)"},{"id":"en-BB","text":"English (Barbados)"},{"id":"en-BM","text":"English (Bermuda)"},{"id":"en-BS","text":"English (Bahamas)"},{"id":"en-BW","text":"English (Botswana)"},{"id":"en-BZ","text":"English (Belize)"},{"id":"en-CA","text":"English (Canada)"},{"id":"en-CC","text":"English (Cocos (Keeling) Islands)"},{"id":"en-CK","text":"English (Cook Islands)"},{"id":"en-CM","text":"English (Cameroon)"},{"id":"en-CX","text":"English (Christmas Island)"},{"id":"en-DM","text":"English (Dominica)"},{"id":"en-ER","text":"English (Eritrea)"},{"id":"en-FJ","text":"English (Fiji)"},{"id":"en-FK","text":"English (Falkland Islands (Malvinas))"},{"id":"en-FM","text":"English (Micronesia, Federated States Of)"},{"id":"en-GD","text":"English (Grenada)"},{"id":"en-GH","text":"English (Ghana)"},{"id":"en-GI","text":"English (Gibraltar)"},{"id":"en-GM","text":"English (Gambia)"},{"id":"en-GS","text":"English (South Georgia and the South Sandwich Islands)"},{"id":"en-GU","text":"English (Guam)"},{"id":"en-GY","text":"English (Guyana)"},{"id":"en-HK","text":"English (Hong Kong)"},{"id":"en-HM","text":"English (Heard and McDonald Islands)"},{"id":"en-IE","text":"English (Ireland)"},{"id":"en-IN","text":"English (India)"},{"id":"en-IO","text":"English (British Indian Ocean Territory)"},{"id":"en-JM","text":"English (Jamaica)"},{"id":"en-KE","text":"English (Kenya)"},{"id":"en-KI","text":"English (Kiribati)"},{"id":"en-KN","text":"English (Saint Kitts And Nevis)"},{"id":"en-KY","text":"English (Cayman Islands)"},{"id":"en-LC","text":"English (Saint Lucia)"},{"id":"en-LR","text":"English (Liberia)"},{"id":"en-LS","text":"English (Lesotho)"},{"id":"en-MH","text":"English (Marshall Islands)"},{"id":"en-MP","text":"English (Northern Mariana Islands)"},{"id":"en-MS","text":"English (Montserrat)"},{"id":"en-MT","text":"English (Malta)"},{"id":"en-MU","text":"English (Mauritius)"},{"id":"en-MW","text":"English (Malawi)"},{"id":"en-MY","text":"English (Malaysia)"},{"id":"en-NA","text":"English (Namibia)"},{"id":"en-NF","text":"English (Norfolk Island)"},{"id":"en-NG","text":"English (Nigeria)"},{"id":"en-NR","text":"English (Nauru)"},{"id":"en-NU","text":"English (Niue)"},{"id":"en-NZ","text":"English (New Zealand)"},{"id":"en-PG","text":"English (Papua New Guinea)"},{"id":"en-PH","text":"English (Philippines)"},{"id":"en-PK","text":"English (Pakistan)"},{"id":"en-PN","text":"English (Pitcairn)"},{"id":"en-PR","text":"English (Puerto Rico)"},{"id":"en-PW","text":"English (Palau)"},{"id":"en-RW","text":"English (Rwanda)"},{"id":"en-SB","text":"English (Solomon Islands)"},{"id":"en-SC","text":"English (Seychelles)"},{"id":"en-SD","text":"English (Sudan)"},{"id":"en-SG","text":"English (Singapore)"},{"id":"en-SH","text":"English (Saint Helena)"},{"id":"en-SL","text":"English (Sierra Leone)"},{"id":"en-SZ","text":"English (Swaziland)"},{"id":"en-TC","text":"English (Turks and Caicos Islands)"},{"id":"en-TK","text":"English (Tokelau)"},{"id":"en-TO","text":"English (Tonga)"},{"id":"en-TT","text":"English (Trinidad and Tobago)"},{"id":"en-TV","text":"English (Tuvalu)"},{"id":"en-TZ","text":"English (Tanzania, United Republic of)"},{"id":"en-UG","text":"English (Uganda)"},{"id":"en-UM","text":"English (United States Minor Outlying Islands)"},{"id":"en-US","text":"English (United States)"},{"id":"en-VC","text":"English (Saint Vincent And The Grenedines)"},{"id":"en-VG","text":"English (Virgin Islands, British)"},{"id":"en-VI","text":"English (Virgin Islands, U.S.)"},{"id":"en-VU","text":"English (Vanuatu)"},{"id":"en-WS","text":"English (Samoa)"},{"id":"en-ZA","text":"English (South Africa)"},{"id":"en-ZM","text":"English (Zambia)"},{"id":"en-ZW","text":"English (Zimbabwe)"}]},{"id":"et-EE","text":"Estonian (Estonia)"},{"id":"eu","text":"Basque"},{"id":"fa-IR","text":"Persian (Iran, Islamic Republic Of)"},{"id":"fj-FJ","text":"Fijian (Fiji)"},{"id":"fi","text":"Finnish (Finland)"},{"text":"French","children":[{"id":"fr-BE","text":"French (Belgium)"},{"id":"fr-BF","text":"French (Burkina Faso)"},{"id":"fr-BI","text":"French (Burundi)"},{"id":"fr-BJ","text":"French (Benin)"},{"id":"fr-CA","text":"French (Canada)"},{"id":"fr-CD","text":"French (Congo, The Democratic Republic Of The)"},{"id":"fr-CF","text":"French (Central African Republic)"},{"id":"fr-CG","text":"French (Congo)"},{"id":"fr-CH","text":"French (Switzerland)"},{"id":"fr-CI","text":"French (C\u00f4te D'Ivoire)"},{"id":"fr-CM","text":"French (Cameroon)"},{"id":"fr-DJ","text":"French (Djibouti)"},{"id":"fr-EH","text":"French (Western Sahara)"},{"id":"fr-FR","text":"French (France)"},{"id":"fr-GA","text":"French (Gabon)"},{"id":"fr-GF","text":"French (French Guiana)"},{"id":"fr-GN","text":"French (Guinea)"},{"id":"fr-GP","text":"French (Guadeloupe)"},{"id":"fr-GQ","text":"French (Equatorial Guinea)"},{"id":"fr-HT","text":"French (Haiti)"},{"id":"fr-KM","text":"French (Comoros)"},{"id":"fr-LB","text":"French (Lebanon)"},{"id":"fr-LU","text":"French (Luxembourg)"},{"id":"fr-MC","text":"French (Monaco)"},{"id":"fr-MG","text":"French (Madagascar)"},{"id":"fr-ML","text":"French (Mali)"},{"id":"fr-MQ","text":"French (Martinique)"},{"id":"fr-MR","text":"French (Mauritania)"},{"id":"fr-NC","text":"French (New Caledonia)"},{"id":"fr-NE","text":"French (Niger)"},{"id":"fr-PF","text":"French (French Polynesia)"},{"id":"fr-PM","text":"French (Saint Pierre And Miquelon)"},{"id":"fr-RE","text":"French (R\u00e9union)"},{"id":"fr-RW","text":"French (Rwanda)"},{"id":"fr-SC","text":"French (Seychelles)"},{"id":"fr-SN","text":"French (Senegal)"},{"id":"fr-TD","text":"French (Chad)"},{"id":"fr-TG","text":"French (Togo)"},{"id":"fr-TN","text":"French (Tunisia)"},{"id":"fr-VU","text":"French (Vanuatu)"},{"id":"fr-WF","text":"French (Wallis and Futuna)"},{"id":"fr-YT","text":"French (Mayotte)"}]},{"id":"ga-IE","text":"Irish (Ireland)"},{"id":"gu","text":"Gujarati"},{"text":"Hebrew","children":[{"id":"he-IL","text":"Hebrew (Israel)"}]},{"text":"Hindi","children":[{"id":"hi-FJ","text":"Hindi (Fiji)"},{"id":"hi-IN","text":"Hindi (India)"}]},{"text":"Croatian","children":[{"id":"hr-BA","text":"Croatian (Bosnia and Herzegovina)"},{"id":"hr-HR","text":"Croatian (Croatia)"},{"id":"hr-ME","text":"Croatian (Montenegro)"}]},{"id":"hu-HU","text":"Hungarian (Hungary)"},{"text":"Armenian","children":[{"id":"hy-AM","text":"Armenian (Armenia)"},{"id":"hy-AZ","text":"Armenian (Azerbaijan)"},{"id":"hy-CY","text":"Armenian (Cyprus)"}]},{"id":"id-ID","text":"Indonesian (Indonesia)"},{"id":"is-IS","text":"Icelandic (Iceland)"},{"text":"Italian","children":[{"id":"it-CH","text":"Italian (Switzerland)"},{"id":"it-IT","text":"Italian (Italy)"},{"id":"it-SM","text":"Italian (San Marino)"},{"id":"it-VA","text":"Italian (Holy See (Vatican City State))"}]},{"id":"ja-JP","text":"Japanese (Japan)"},{"id":"ka-GE","text":"Georgian (Georgia)"},{"id":"km-KH","text":"Central Khmer (Cambodia)"},{"text":"Korean","children":[{"id":"ko-KP","text":"Korean (Korea, Democratic People's Republic Of)"},{"id":"ko-KR","text":"Korean (Korea, Republic of)"}]},{"id":"la-VA","text":"Latin (Holy See (Vatican City State))"},{"id":"lv-LV","text":"Latvian (Latvia)"},{"id":"lt-LT","text":"Lithuanian (Lithuania)"},{"id":"ml","text":"Malayalam"},{"id":"mr","text":"Marathi"},{"id":"mk-MK","text":"Macedonian (Macedonia, the Former Yugoslav Republic Of)"},{"id":"mt-MT","text":"Maltese (Malta)"},{"id":"mn-MN","text":"Mongolian (Mongolia)"},{"id":"mi","text":"Maori"},{"text":"Malay","children":[{"id":"ms-BN","text":"Malay (Brunei Darussalam)"},{"id":"ms-CX","text":"Malay (Christmas Island)"},{"id":"ms-SG","text":"Malay (Singapore)"}]},{"id":"ne-NP","text":"Nepali (Nepal)"},{"text":"Dutch","children":[{"id":"nl-AN","text":"Dutch (Netherlands Antilles)"},{"id":"nl-AW","text":"Dutch (Aruba)"},{"id":"nl-BE","text":"Dutch (Belgium)"},{"id":"nl-NL","text":"Dutch (Netherlands)"},{"id":"nl-SR","text":"Dutch (Suriname)"}]},{"text":"Norwegian","children":[{"id":"no-NL","text":"Norwegian (Norway)"},{"id":"no-SJ","text":"Norwegian (Svalbard And Jan Mayen)"}]},{"id":"pa","text":"Panjabi"},{"id":"pl-PL","text":"Polish (Poland)"},{"text":"Portuguese","children":[{"id":"pt-AO","text":"Portuguese (Angola)"},{"id":"pt-BR","text":"Portuguese (Brazil)"},{"id":"pt-CV","text":"Portuguese (Cape Verde)"},{"id":"pt-GW","text":"Portuguese (Guinea-Bissau)"},{"id":"pt-MO","text":"Portuguese (Macao)"},{"id":"pt-MZ","text":"Portuguese (Mozambique)"},{"id":"pt-PT","text":"Portuguese (Portugal)"},{"id":"pt-ST","text":"Portuguese (Sao Tome and Principe)"}]},{"id":"qu-BO","text":"Quechua (Bolivia)"},{"text":"Romanian","children":[{"id":"ro-MD","text":"Romanian (Moldova, Republic of)"},{"id":"ro-RO","text":"Romanian (Romania)"}]},{"text":"Russian","children":[{"id":"ru-AM","text":"Russian (Armenia)"},{"id":"ru-BY","text":"Russian (Belarus)"},{"id":"ru-KG","text":"Russian (Kyrgyzstan)"},{"id":"ru-KZ","text":"Russian (Kazakhstan)"},{"id":"ru-RU","text":"Russian (Russian Federation)"},{"id":"ru-TJ","text":"Russian (Tajikistan)"},{"id":"ru-TM","text":"Russian (Turkmenistan)"},{"id":"ru-UZ","text":"Russian (Uzbekistan)"}]},{"text":"Slovak","children":[{"id":"sk-CZ","text":"Slovak (Czech Republic)"},{"id":"sk-SK","text":"Slovak (Slovakia)"}]},{"id":"sl-SI","text":"Slovenian (Slovenia)"},{"text":"Samoan","children":[{"id":"sm-AS","text":"Samoan (American Samoa)"},{"id":"sm-WS","text":"Samoan (Samoa)"}]},{"text":"Spanish","children":[{"id":"es-AR","text":"Spanish (Argentina)"},{"id":"es-BO","text":"Spanish (Bolivia)"},{"id":"es-BZ","text":"Spanish (Belize)"},{"id":"es-CL","text":"Spanish (Chile)"},{"id":"es-CO","text":"Spanish (Colombia)"},{"id":"es-CR","text":"Spanish (Costa Rica)"},{"id":"es-CU","text":"Spanish (Cuba)"},{"id":"es-DO","text":"Spanish (Dominican Republic)"},{"id":"es-EC","text":"Spanish (Ecuador)"},{"id":"es-EH","text":"Spanish (Western Sahara)"},{"id":"es-ES","text":"Spanish (Spain)"},{"id":"es-GQ","text":"Spanish (Equatorial Guinea)"},{"id":"es-GT","text":"Spanish (Guatemala)"},{"id":"es-GU","text":"Spanish (Guam)"},{"id":"es-HN","text":"Spanish (Honduras)"},{"id":"es-MX","text":"Spanish (Mexico)"},{"id":"es-NI","text":"Spanish (Nicaragua)"},{"id":"es-PA","text":"Spanish (Panama)"},{"id":"es-PE","text":"Spanish (Peru)"},{"id":"es-PR","text":"Spanish (Puerto Rico)"},{"id":"es-PY","text":"Spanish (Paraguay)"},{"id":"es-SV","text":"Spanish (El Salvador)"},{"id":"es-UY","text":"Spanish (Uruguay)"},{"id":"es-VE","text":"Spanish (Venezuela, Bolivarian Republic of)"}]},{"text":"Albanian","children":[{"id":"sq-AL","text":"Albanian (Albania)"},{"id":"sq-ME","text":"Albanian (Montenegro)"}]},{"text":"Serbian","children":[{"id":"sr-BA","text":"Serbian (Bosnia and Herzegovina)"},{"id":"sr-ME","text":"Serbian (Montenegro)"},{"id":"sr-RS","text":"Serbian (Serbia)"}]},{"text":"Swahili","children":[{"id":"sw-CD","text":"Swahili (Congo, The Democratic Republic Of The)"},{"id":"sw-KE","text":"Swahili (Kenya)"},{"id":"sw-TZ","text":"Swahili (Tanzania, United Republic of)"},{"id":"sw-UG","text":"Swahili (Uganda)"}]},{"text":"Swedish","children":[{"id":"sv-SE","text":"Swedish (Sweden)"}]},{"text":"Tamil","children":[{"id":"ta-LK","text":"Tamil (Sri Lanka)"},{"id":"ta-SG","text":"Tamil (Singapore)"}]},{"id":"tt","text":"Tatar"},{"id":"te","text":"Telugu"},{"id":"th-TH","text":"Thai (Thailand)"},{"id":"to-TO","text":"Tonga (Tonga Islands) (Tonga)"},{"text":"Turkish","children":[{"id":"tr-CY","text":"Turkish (Cyprus)"},{"id":"tr-TR","text":"Turkish (Turkey)"}]},{"id":"uk-UA","text":"Ukrainian (Ukraine)"},{"text":"Urdu","children":[{"id":"ur-FJ","text":"Urdu (Fiji)"},{"id":"ur-PK","text":"Urdu (Pakistan)"}]},{"text":"Uzbek","children":[{"id":"uz-AF","text":"Uzbek (Afghanistan)"},{"id":"uz-UZ","text":"Uzbek (Uzbekistan)"}]},{"id":"vi-VN","text":"Vietnamese (Viet Nam)"},{"id":"xh-ZA","text":"Xhosa (South Africa)"},{"text":"Chinese","children":[{"id":"zh-CN","text":"Chinese (China)"},{"id":"zh-CX","text":"Chinese (Christmas Island)"},{"id":"zh-HK","text":"Chinese (Hong Kong)"},{"id":"zh-MO","text":"Chinese (Macao)"},{"id":"zh-TW","text":"Chinese (Taiwan, Republic Of China)"}]}];

  Item.languageLookup = Item._setLanguageLookup(Item.languages);

  Item.prototype.tagList2Tags = function() {
    var self = this;
    self.tags = [];
    angular.forEach((self.tagList || []), function (v,k) {
      self.tags.push(v['text']);
    });
  };

  Item.prototype.getTitle = function () {
    if (this.title) { return this.title; }
    if (this.episodeTitle) { return this.episodeTitle + " : " + this.identifier; }
    if (this.seriesTitle) { return this.seriesTitle + " : " + this.identifier; }
  } 

  Item.prototype.getDescription = function () {
    if (this.description) { return this.description; }
    if (this.notes) { return this.notes; }
  }

  Item.prototype.getThumbClass = function () {
    if (this.audioFiles && this.audioFiles.length > 0) {
      return "icon-volume-up";
    } else {
      return "icon-file-alt"
    }
  }

  Item.prototype.link = function () {
    return "/collections/" + this.collectionId + "/items/" + this.id; 
  }

  Item.prototype.getDurationString = function () {
    var d = new Date(this.duration * 1000);
    return d.getUTCHours() + ":" + d.getUTCMinutes() + ":" + d.getUTCSeconds();
  }

  Item.prototype.adopt = function (collectionId) {
    var self = this;
    this.adoptToCollection = collectionId;
    return this.update().then(function (data) {
      self.adoptToCollection = undefined;
      return data;
    });
  }

  Item.prototype.contributors = function (role) {
    var result = [];
    angular.forEach(this.contributions, function (contribution) {
      if (contribution.role == role) {
        result.push(contribution.person.name);
      } else {
      }
    });
    return result;
  }

  Item.prototype.addAudioFile = function (file, options) {
    var options = options || {};
    var item = this;
    var audioFile = new AudioFile({itemId: item.id});
    audioFile.create().then( function () {
      audioFile.filename = audioFile.cleanFileName(file.name);
      item.audioFiles = item.audioFiles || [];
      item.audioFiles.push(audioFile);
      options.token = item.token;
      audioFile.upload(file, options);
    });
    return audioFile;
  }

  // update existing audioFiles
  Item.prototype.updateAudioFiles = function () {
    var item = this;

    var keepAudioFiles = [];
    angular.forEach(item.audioFiles, function (audioFile, index) {

      // console.log('updateAudioFiles', index, audioFile);
      var af = new AudioFile(audioFile);
      af.itemId = item.id;

      // delete c if marked for delete
      if (af._delete) {
        // console.log('updateAudioFiles delete', audioFile, item);
        af.delete();
      } else {
        keepAudioFiles.push(audioFile);
      }
      // else if (af.id) {
      //   af.update();
      // }
    });
    item.audioFiles = keepAudioFiles;
  }

  Item.prototype.playable = function () {
    return this.audioFiles && this.audioFiles.length > 0;
  }

  Item.prototype.entityShortList = function () {
    this._entityShortList = this._entityShortList || [];
    this._entityShortList.length = 0;
    if (this.tags && this.tags.length >= 5) {
      for (var i=0; i<5; i++) {
        this._entityShortList.push(this.tags[i]);
      }
    } else {
      angular.forEach(this.tags, function (tag) {
        this._entityShortList.push(tag);
      }, this);
      var i = 0;
      if (this.entities) {
        while (i < this.entities.length && this._entityShortList.length <= 5) {
          this._entityShortList.push(this.entities[i].name);
          i++;
        }
      }
    }
    return this._entityShortList;
  }

  Item.prototype.paused = function () {
    return this.playable() && !this.playing();
  }

  Item.prototype.loadedIntoPlayer = function () {
    var me = false;
    if (Player.nowPlayingUrl() && this.playable()) {
      var nowPlaying = Player.nowPlayingUrl().split('?')[0];
      angular.forEach(this.audioFiles, function (file) {
        if (file.url && (nowPlaying == file.url.split('?')[0])) {
          me = true;
        }
      });
    } else {
      return false;
    }
    return me;
  }

  Item.prototype.playing = function() {
    return this.loadedIntoPlayer() && !Player.paused();
  }

  // update existing contributions
  Item.prototype.updateContributions = function () {
    var item = this;

    var keepContributions = [];
    angular.forEach(item.contributions, function (contribution, index) {

      var c = new Contribution(contribution);
      c.itemId = item.id;

      // delete c if marked for delete
      if (c._delete) {
        c.delete();
        // item.contributions.splice(index, 1);
      } else  {
        keepContributions.push(c);

        if (!c.person.id  || (c.person.id == 'new')) {

          var p = new Person({'name':c.person.name, 'collectionId':item.collectionId});

          p.create().then( function() {
            c.personId = p.id;
            if (!c.id || (c.id == 'new')) {
              c.id = null;
              c.create();
            } else {
              c.update();
            }
          });
        } else if (!c.id || (c.id == 'new')) {
          c.id = null;
          c.personId = c.person.id;
          c.create();
        } else {
          c.personId = c.person.id;
          c.update();
        }

      }
    });
    item.contributions = keepContributions;
  }

  Item.prototype.play = function () {
    if (!this.loadedIntoPlayer()) {
      Player.play(this.audioFiles[0].url, this.getTitle());
    } else {
      Player.play();
    }
  };

  Item.prototype.pause = function () {
    if (this.playing()) {
      Player.pause();
    }
  }

  Item.prototype.standardRoles = ['producer', 'interviewer', 'interviewee', 'creator', 'host'];

  return Item;
}])
.filter('titleize', function () {
  return function (value) {
    if (!angular.isString(value)) {
      return value;
    }
    return value.slice(0,1).toUpperCase() + value.slice(1).replace(/([A-Z])/g, ' $1');
  }
})
.filter('pluralize', function () {
  return function (value) {
    if (!angular.isString(value)) {
      return value;
    }
    return value + "s";
  }
});
