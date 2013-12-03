# Pop-Up Archive

[![Build Status](https://travis-ci.org/PRX/pop-up-archive.png?branch=master)](https://travis-ci.org/PRX/pop-up-archive)
[![Dependency Status](https://gemnasium.com/PRX/pop-up-archive.png)](https://gemnasium.com/PRX/pop-up-archive)
[![Coverage Status](https://coveralls.io/repos/PRX/pop-up-archive/badge.png)](https://coveralls.io/r/PRX/pop-up-archive)
[![Code Climate](https://codeclimate.com/github/PRX/pop-up-archive.png)](https://codeclimate.com/github/PRX/pop-up-archive)

<table>
  <tr>
    <th>
      Ruby Version
    </th>
    <td>
      2.0.0-p247
    </td>
  </tr>
  <tr>
    <th>
      Rails Version
    </th>
    <td>
      3.2.14
    </td>
  </tr>
  <tr>
    <th>
      Production Deployment
    </th>
    <td>
      git@heroku.com:pop-up-archive.git - http://pop-up-archive.herokuapp.com
    </td>
  </tr>
</table>

### Recommended setup

This guide expects that you have git and homebrew installed, and have a ruby environment set up with 2.0.0-p247 (using RVM or rbenv). We also assume you are using Pow, and have the development site running at http://pop-up-archive.dev. This is not required, but some aspects of the guide may not be appropriate for different configurations.

    brew install redis elasticsearch postgres
    git clone git@github.com:PRX/pop-up-archive.git
    curl get.pow.cx | sh
    gem install powder bundler
    cd pop-up-archive
    bundle install
    powder link
    cp config/env_vars.example config/env_vars
    

#### Environment variables

In order to mimic the way Heroku works, many application configuration settings are defined with environment variables. If you are using foreman/etc you may have a different way of accomplishing this. You can also use the included support for the config/env_vars file.

##### You should not check config/env_vars into source control

You will need to set the SECRET_TOKEN value for the app to start (the default value is too short). The other default value may not be required. If need to point the app to a database or database user different than what is in the included database.yml, you should do that with an environment variable. Once complete:

    bundle exec rake db:create
    rake db:setup
    rake db:migrate

### Development

    powder open

The site should now be running. If you need to use sidekiq, or elasticsearch, you may need to start other services manually.

### Testing

All that should be required is running `guard` in the project root. You can also just run `rake`.

We have the project on Travis-CI. If you submit a pull request, I assume it should check on that. I don't know.


### Copyright & License

The Pop Up Archive software is released under the [Affero GNU General Public License](http://www.gnu.org/licenses/agpl.html).

Copyright (c) 2013 The Public Radio Exchange, www.prx.org

This program is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
