// [WriteFile Name=ListRelatedFeatures, Category=Features]
// [Legal]
// Copyright 2017 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

import QtQuick 2.6
import QtQuick.Controls 2.2
import Esri.ArcGISRuntime 100.4
import Esri.ArcGISExtras 1.1

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property FeatureLayer alaskaNationalParks: null
    property real scaleFactor: 1

    MapView {
        id: mapView
        anchors.fill: parent

        SelectionProperties {
            color: "yellow"
        }

        // bind the insets to the attribute view so the attribution text shows when the view expands
        viewInsets.bottom: attributeView.height / scaleFactor

        Map {
            id: map
            initUrl: "https://arcgis.com/home/item.html?id=dcc7466a91294c0ab8f7a094430ab437"

            onLoadStatusChanged: {
                if (loadStatus !== Enums.LoadStatusLoaded)
                    return;

                // get the Alaska National Parks feature layer
                map.operationalLayers.forEach(function(fl) {
                    if (fl.name.indexOf("- Alaska National Parks") !== -1) {
                        alaskaNationalParks = fl;
                    }
                });
            }
        }

        onMouseClicked: {
            // hide the attribute view
            attributeView.height = 0;

            // clear the list model
            relatedFeaturesModel.clear();

            // create objects required to do a selection with a query
            var clickPoint = mouse.mapPoint;
            var mapTolerance = 10 * mapView.unitsPerDIP;
            var envelope = ArcGISRuntimeEnvironment.createObject("Envelope", {
                                                                     xMin: clickPoint.x - mapTolerance,
                                                                     yMin: clickPoint.y - mapTolerance,
                                                                     xMax: clickPoint.x + mapTolerance,
                                                                     yMax: clickPoint.y + mapTolerance,
                                                                     spatialReference: map.spatialReference
                                                                 });
            var queryParams = ArcGISRuntimeEnvironment.createObject("QueryParameters");
            queryParams.geometry = envelope;
            queryParams.spatialRelationship = Enums.SpatialRelationshipIntersects;

            // clear any selections
            alaskaNationalParks.clearSelection();

            // select features
            alaskaNationalParks.selectFeaturesWithQuery(queryParams, Enums.SelectionModeNew);
        }
    }

    Connections {
        target: alaskaNationalParks

        onSelectFeaturesStatusChanged: {
            if (alaskaNationalParks.selectFeaturesStatus === Enums.TaskStatusErrored) {
                var errorString = "Error: %1".arg(alaskaNationalParks.error.message);
                msgDialog.text = errorString;
                msgDialog.open();
                console.log(errorString);
            } else if (alaskaNationalParks.selectFeaturesStatus === Enums.TaskStatusCompleted) {
                var featureQueryResult = alaskaNationalParks.selectFeaturesResult;

                // iterate over features returned
                while (featureQueryResult.iterator.hasNext) {
                    var arcGISFeature = featureQueryResult.iterator.next();
                    var selectedTable = arcGISFeature.featureTable;

                    // connect signal
                    selectedTable.queryRelatedFeaturesStatusChanged.connect(function() {
                        if (selectedTable.queryRelatedFeaturesStatus !== Enums.TaskStatusCompleted)
                            return;

                        var relatedFeatureQueryResultList = selectedTable.queryRelatedFeaturesResults;

                        // iterate over returned RelatedFeatureQueryResults
                        for (var i = 0; i < relatedFeatureQueryResultList.length; i++) {

                            // iterate over Features returned
                            var iter = relatedFeatureQueryResultList[i].iterator;
                            while (iter.hasNext) {
                                var feat = iter.next();
                                var displayFieldName = feat.featureTable.layerInfo.displayFieldName;
                                var serviceLayerName = feat.featureTable.layerInfo.serviceLayerName;
                                var displayFieldValue = feat.attributes.attributeValue(displayFieldName);

                                // add the related feature info to a list model
                                var listElement = {
                                    "displayFieldName" : displayFieldName,
                                    "displayFieldValue" : displayFieldValue,
                                    "serviceLayerName" : serviceLayerName
                                };
                                relatedFeaturesModel.append(listElement);
                            }
                        }

                        // show the attribute view
                        attributeView.height = 200 * scaleFactor
                    });

                    // zoom to the feature
                    mapView.setViewpointGeometryAndPadding(arcGISFeature.geometry, 100)

                    // query related features
                    selectedTable.queryRelatedFeatures(arcGISFeature);
                }
            }
        }
    }

    Rectangle {
        id: attributeView
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 0

        // Animate the expand and collapse of the legend
        Behavior on height {
            SpringAnimation {
                spring: 3
                damping: 0.4
            }
        }

        ListView {
            anchors {
                fill: parent
                margins: 5 * scaleFactor
            }

            clip: true
            model: relatedFeaturesModel
            spacing: 5 * scaleFactor

            // Create delegate to display the attributes
            delegate: Rectangle {
                width: rootRectangle.width
                height: childrenRect.height
                color: "transparent"

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: 10
                                     * scaleFactor
                    text: displayFieldValue
                    font.pixelSize: 12 * scaleFactor
                }
            }

            // Create a section to separate features by table
            section {
                property: "serviceLayerName"
                criteria: ViewSection.FullString
                labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
                delegate: Rectangle {
                    width: rootRectangle.width
                    height: childrenRect.height
                    color: "lightsteelblue"

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: section
                        font {
                            bold: true
                            pixelSize: 13 * scaleFactor
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: relatedFeaturesModel
    }

    Dialog {
        id: msgDialog
        modal: true
        x: Math.round(parent.width - width) / 2
        y: Math.round(parent.height - height) / 2
        standardButtons: Dialog.Ok
        property alias text : textLabel.text
        Text {
            id: textLabel
            text: "Executing geoprocessing failed."
        }
    }
}
