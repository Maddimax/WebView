import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
    property ListModel viewModel: ListModel { }

    property var database : LocalStorage.openDatabaseSync("WebView", "1.0", "Usersettings", 1000000);
    function init() {
        database.transaction(
                    function(tx) {
                        // Create the database if it doesn't already exist
                        tx.executeSql('CREATE TABLE IF NOT EXISTS Views(title TEXT, itemUrl TEXT)');

                        // Add (another) greeting row
                        //tx.executeSql('INSERT INTO Views VALUES(?, ?)', [ 'RIPPA', 'http://rippa.localdomain/Main' ]);
                    }
                    )
    }

    function viewModelIndexFromDbIndex(dbIndex) {
        for(var i=0;i<viewModel.count;i++) {
            if( viewModel.get(i).dbId == dbIndex) {
                return i
            }
        }
        return -1
    }

    function updateModel() {
        database.transaction(function (tx) {
            var results = tx.executeSql('SELECT rowid, title, itemUrl FROM Views order by rowid asc')

            var existingRowIds = []
            for (var i = 0; i < results.rows.length; i++) {
                var viewIdx = viewModelIndexFromDbIndex(results.rows.item(i).rowid)

                existingRowIds.push(results.rows.item(i).rowid)

                var dict = {
                    dbId: results.rows.item(i).rowid,
                    itemTitle: results.rows.item(i).title,
                    itemUrl: Qt.resolvedUrl(results.rows.item(i).itemUrl)
                }

                if(dict.itemTitle === null) {
                    dict.itemTitle = ""
                }

                if( viewIdx === -1) {
                    viewModel.append(dict)
                }
                else {
                    viewModel.set(viewIdx, dict)
                }
            }

            for(i=0;i<viewModel.count;i++) {
                if(existingRowIds.indexOf(viewModel.get(i).dbId) === -1) {
                    viewModel.remove(i)
                }
            }
        })
    }

    function remove(index) {
        database.transaction(function (tx) {
            tx.executeSql('DELETE FROM Views WHERE rowId = ?', [index])
        })
        updateModel()
    }

    function add(title, itemUrl) {
        database.transaction(function (tx) {
            tx.executeSql('INSERT INTO Views VALUES(?, ?)', [ title, itemUrl ]);
        })

        updateModel()
    }

    function set(dbId, title, itemUrl) {
        database.transaction(function (tx) {
            tx.executeSql('UPDATE Views SET title = ?, itemUrl = ? WHERE rowid = ?', [ title, itemUrl, dbId ]);
        })

        updateModel()
    }

    Component.onCompleted: {
        init()

        updateModel()
    }
}