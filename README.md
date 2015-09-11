marcxml2accession_single_agent
=============================

Only create a single agent_person when importing Marc XML to Accessions

# Getting Started

Download the latest release from the Releases tab in Github:

    cd /path/to/archivesspace/plugins
    git clone https://github.com/quideneuf/marcxml2accession_single_agent

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'marcxml2accession_single_agent']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

See also:

  https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md

