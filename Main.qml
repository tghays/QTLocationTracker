/* Copyright 2020 Solutions Platform Geospatial, LLC
 *
 * It is unlawful to distribute this content without the expresesd written
 * approval of Solutions Platform Geospatial, LLC.  This content is intended for the
 * clients of Solutions Platform Geospatial, LLC.
 *
 */

import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0
import QtPositioning 5.3
import QtSensors 5.3
import QtWebView 1.1

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.7
import Esri.ArcGISRuntime.Toolkit.Dialogs 100.7
import Esri.ArcGISRuntime.Toolkit.Controls 100.7
import ArcGIS.AppFramework.Notifications.Local 1.0
import ArcGIS.AppFramework.Notifications 1.0

import "controls" as Controls




App {
    id: app
    width: 414
    height: 736
    function units(value) {
        return AppFramework.displayScaleFactor * value
    }
    property real scaleFactor: AppFramework.displayScaleFactor
    property int baseFontSize : app.info.propertyValue("baseFontSize", 15 * scaleFactor) + (isSmallScreen ? 0 : 3)
    property bool isSmallScreen: (width || height) < units(400)
    property string trackMode: "Start Tracking"
    property string stopMode: "Stop Tracking"
    property string closeMode: "Close"
    property string currentModeText: stopMode
    property string currentModeImage:"assets/Stop.png"

    property string locText: "Please Log In To Continue"

    property var user: portal.portalUser

    property var currentLocation: null
    property var tempLocation: null
    property var currentTime: new Date().getTime();
    property var tempTime: 0
    property var updateTime: null
    property var newFeature: false
    property var lastEditDate: null

    property var updatingFeature: null
    property var partEdit: null
    property var notifTitle: "Solutions Platform Tracking Notification"
    property var notifTime: 1001
    property var newPartIX: null

    //property var minDist: 1
    property var minDist: .00000000001
    property var minTime: 5
    property var features: null

    onLowMemory: {
        trackingNotification.schedule(notifTitle,"Running on low memory",notifTime)
        console.log("application running low on memory")
    }

    SpatialReference {
        id:addFeatureSR
        wkid: 3857
    }

    PositionSource {
        id:posSource
        active: true
        onActiveChanged: {
            if (PositionSource.active === false) {
                trackingNotification.schedule(notifTitle,"Lost position source", notifTime)
                console.log("POSITION SOURCE INACTIVE")
            }
        }

        preferredPositioningMethods: PositionSource.SatellitePositioningMethods
        //updateInterval: minTime * 1000 *2
    }

    Page{
        anchors.fill: parent
        header: ToolBar{
            id:header
            width: parent.width
            height: 50 * scaleFactor
            Material.background: "#8f499c"
            Controls.HeaderBar{}
        }

        // sample starts here ------------------------------------------------------------------
        contentItem: Rectangle{
            anchors.top:header.bottom

            QueryParameters {
                id: params
                orderByFields: OrderBy {
                    fieldName: "EditDate"
                    sortOrder: Enums.SortOrderDescending
                }
            }

            AuthenticationView {
                id: authView
                authenticationManager: AuthenticationManager
            }

            PolylineBuilder {
                id: polylineBuild
                spatialReference: addFeatureSR
            }

            Polyline {
                id: newPolyLine
                spatialReference: addFeatureSR
            }

            PartCollection {
                id: newPartCollection
                spatialReference: addFeatureSR
            }

            Part {
                id:newPart
                spatialReference: addFeatureSR
            }

            Item {
                LocalNotification {
                    id: trackingNotification
                    onTriggered: {
                        if(Vibration.supported) {
                            Vibration.vibrate()
                        }
                    }
                }
            }

            // Create MapView that contains a Map with the Imagery with Labels Basemap
            MapView {
                id: mapView
                anchors.fill: parent
                allowMagnifierToPanMap: false
                Map {
                    id: mapObject
                    BasemapOpenStreetMap {}

                    // start the location display
                    onLoadStatusChanged: {
                        if (loadStatus === Enums.LoadStatusLoaded) {
                            // populate list model with modes
                            autoPanListModel.append({name: trackMode, image:"assets/Navigation.png"});
                            autoPanListModel.append({name: stopMode, image:"assets/Stop.png"});
                            autoPanListModel.append({name: closeMode, image:"assets/Close.png"});
                        }
                    }
                }

                // set the location display's position source
                locationDisplay {
                    id: locDisplay
                    positionSource: posSource
                    compass: Compass {}

                    onLocationChanged: {
                        if (currentLocation === null) {
                            currentLocation = locationDisplay.location.position

                        }
                        else {
                            tempLocation = locationDisplay.location.position
                            //app.locText = 'temp loc: ' + tempLocation.x

                            if (tempLocation !== currentLocation & ((tempTime - currentTime) / 1000) > minTime) {

                                console.log("temp x: " + tempLocation.x + ", cur x:" + currentLocation.x)

                                // Calculate distance bettwen currentLocation and tempLocation
                                var dist = GeometryEngine.distance(currentLocation,tempLocation);

                                if (dist > minDist) {
                                    var tempLocationProj = GeometryEngine.project(tempLocation,addFeatureSR)

                                    if (newFeature === false){

                                        var initPartCount = polylineBuild.parts.size
                                        var initSegmentCount = partEdit.segmentCount

                                        var ix = partEdit.addPoint(tempLocationProj)
                                        polylineBuild.parts.setPart(0,partEdit)
                                        var tempPartCount = polylineBuild.parts.size
                                        var tempSegmentCount = partEdit.segmentCount
                                        console.log("iparts: " + initPartCount + "iSegs: " + initSegmentCount + " tParts: " + tempPartCount + " tSegs: " + tempSegmentCount)

                                        updatingFeature.geometry = polylineBuild.geometry
                                    }
                                    else {

                                        // Add new feature and store in updatingFeature

                                        // Add new part collection here, then add to polylineBuild object
/*
                                        newPart.addPointXY(tempLocationProj.x,tempLocationProj.y)
                                        newPart.addPoint(tempLocationProj.x+1,tempLocationProj.y+1)
                                        newPartCollection.addPart(newPart)
                                        polylineBuild.parts = newPartCollection



                                        //updatingFeature.geometry = newPolyLine
                                        //polylineBuild.geometry = newPolyLine
                                        polylineBuild.addPoint(tempLocationProj)
                                        polylineBuild.addPoint(tempLocationProj)
                                        polylineBuild.addPoint(tempLocationProj)


                                        newPartIX = polylineBuild.parts.addPart(newPart)
                                        console.log("number new parts: " + polylineBuild.parts.size)

                                        partEdit = polylineBuild.parts.part(newPartIX)
                                        console.log('added part, index: ' + newPartIX)

                                        var initPartCount = polylineBuild.parts.size
                                        var initSegmentCount = partEdit.segmentCount
                                        console.log("NEW PART iparts: " + initPartCount+ ", init segment count: " + initSegmentCount)
                                        partEdit.addPoint(tempLocationProj)
                                        partEdit.addPoint(tempLocationProj)
                                        partEdit.addPoint(tempLocationProj)


                                        var partIndex = polylineBuild.parts.indexOf(partEdit)
                                        console.log("part index: " + partIndex)
                                        polylineBuild.parts.setPart(newPartIX,partEdit)

                                        var tempSegmentCount = polylineBuild.parts.part(newPartIX).segmentCount
*/
                                        console.log("templocationproj")
                                        
                                        polylineBuild.geometry = updatingFeature.geometry
                                        var initPartCount = polylineBuild.parts.size


                                        polylineBuild.parts.removePart(1)
                                        polylineBuild.parts.removePart(1)
                                        polylineBuild.parts.removePart(1)
                                        polylineBuild.parts.removePart(1)
                                        polylineBuild.parts.removePart(1)
                                        polylineBuild.parts.removePart(1)



                                        console.log('init geometry empty: ' + polylineBuild.geometry.empty)
                                        console.log('new geometry type: ' + polylineBuild.geometry.geometryType)
                                        console.log("init part count: " + initPartCount)
                                        console.log("polylinebuild spatial reference: " + polylineBuild.parts.spatialReference.wkid)
                                        console.log("polylinebuild has M: " + polylineBuild.hasM + ", polylinebuild has Z: " + polylineBuild.hasZ)
                                        console.log("polylinebuild parent: " + polylineBuild.parent)
                                        console.log("polylinebuild geometrybuildertype: " + polylineBuild.geometryBuilderType)

                                        var tempPartCount = polylineBuild.parts.size
                                        console.log("new geometry part count: " + tempPartCount)

                                        var tempSegmentCount = polylineBuild.parts.part(0).segmentCount
                                        console.log("Added init points, new segment count: " + tempSegmentCount)

                                        updatingFeature = featuretable.createFeatureWithAttributes({"name" : "test"},polylineBuild.geometry)
                                        updatingFeature.load()

                                        console.log('attempting to create feature now')

                                    }



                                    if (featuretable.updateFeatureStatus !== Enums.TaskStatusInProgress) {
                                        if (newFeature === true) {
                                            console.log("New feature identified first time, updating feature in feature table first time")
                                            featuretable.addFeature(updatingFeature)
                                            newFeature = false
                                        }
                                        else {
                                            featuretable.updateFeature(updatingFeature)
                                            //posSource.updateInterval = minTime * 1000 *2
                                            console.log('updating feature table after first time')
                                        }


                                    }

                                }
                                else {
                                    if (updateTime !== null) {
                                        app.locText = 'Location not changing, last update : ' + updateTime.toLocaleTimeString()
                                        console.log('Location not changing, last update : ' + updateTime.toLocaleTimeString() + " position source active: " + posSource.active)
                                    }
                                    else {
                                        app.locText = "Location not changing, initial update not sent"
                                    }

                                }

                                currentLocation = tempLocation
                                currentTime = tempTime
                            }
                            else {
                                //app.locText = 'T diff: ' + (tempTime - currentTime)
                                tempTime = new Date().getTime()

                            }
                        }
                    }
                }

            }
        }

        Portal {
            id: portal
            url: "http://arcgis.com"
            credential: Credential {
                id: credential
                oAuthClientInfo: OAuthClientInfo {
                    oAuthMode: Enums.OAuthModeUser
                    clientId: "SIvRcoSZiarJJXoe"
                    refreshTokenExpirationInterval: -1
                }
                onTokenChanged: {
                    console.log("PORTAL TOKEN REFRESHED")
                }
                onOAuthRefreshTokenChanged: {
                    console.log("PORTAL TOKEN REFRESHED")
                }
            }

            loginRequired: true

            onLoadStatusChanged: {
                if (loadStatus === Enums.LoadStatusFailedToLoad)
                    retryLoad();

                if (loadStatus === Enums.LoadStatusLoaded) {

                    console.log("cred cache enabled: " + AuthenticationManager.credentialCacheEnabled)

                    featuretable.credential = portal.credential
                    app.locText = "Welcome " + user.username
                    console.log("portal expiry: " + portal.credential.tokenExpiry)
                    params.whereClause = "Creator = '%1'".arg(portal.portalUser.username)

                    featuretable.url = "https://services6.arcgis.com/zSX5hRyWi0wnrb2x/ArcGIS/rest/services/TrackingLines/FeatureServer/0"
                    featuretable.queryFeatures(params);
                    console.log("Creator = '%1'".arg(portal.portalUser.username))

                }

            }

            onErrorChanged: {
                if (loadStatus === Enums.LoadStatusFailedToLoad)
                    console.log(error.message);
            }

            Component.onCompleted: {
                load();
                fetchLicenseInfo();

            }
        }


        FeatureLayer {
            id: featurelayer

            ServiceFeatureTable {
                id: featuretable

                onApplyEditsStatusChanged: {
                    if (applyEditsStatus === Enums.TaskStatusCompleted) {
                        updateTime = new Date()
                        if (newFeature === false) {
                            app.locText = "Synced location at: " + updateTime.toLocaleTimeString()
                            console.log("Synced location at: " + updateTime.toLocaleTimeString())
                        }
                        else {
                            newFeature = false
                            app.locText = "Last known location sync: " + lastEditDate
                            console.log("Successfully created new feature in Feature Service at: " + updateTime.toLocaleTimeString())
                        }


                    }
                }


                onUpdateFeatureStatusChanged: {
                    console.log("update feature status : " + updateFeatureStatus)
                    if (updateFeatureStatus === Enums.TaskStatusCompleted) {
                        console.log('updated feature')
                        featuretable.applyEdits()

                        //trackingNotification.schedule(notifTitle, "Updated Feature at " + updateTime.toLocaleTimeString(),notifTime)
                    }
                }

                onAddFeatureStatusChanged: {
                    if (addFeatureStatus === Enums.TaskStatusCompleted){
                        console.log('Successfully added feature locally')
                        featuretable.applyEdits()
                    }
                    else {
                        console.log("add feature status: " + addFeatureStatus)
                    }
                }

                onUrlChanged: {
                    console.log('URL changed')
                }

                onQueryFeaturesResultChanged: {
                    features = []

                    while (queryFeaturesResult.iterator.hasNext) {
                        features.push(queryFeaturesResult.iterator.next());
                    }

                    // Check if there is a feature for this user, if not create new feature
                    if (features.length === 0) {
                        console.log('no features returned')

                        //featuretable.addFeature()
                    }
                    else {
                        //Check if there is a feature created today from this user
                        var today = new Date().toLocaleDateString("en-US")
                        var editDate = features[0].attributes.attributeValue("EditDate").toLocaleDateString("en-US")
                        lastEditDate = features[0].attributes.attributeValue("EditDate").toLocaleString("en-US")

                        console.log('number of features for user: ' + features.length)
                        // If last edit date was today, add tracking points to current feature
                        if (today === editDate) {
                            // Dates are the same, proceed with geometry updates
                            updatingFeature = features[0]
                            updatingFeature.load()
                            polylineBuild.geometry = updatingFeature.geometry
                            console.log("Number of parts in line: " + polylineBuild.parts.size)
                            console.log('existing geometry sr: ' + updatingFeature.geometry.spatialReference.wkid)
                            console.log("existing geometry type: " + updatingFeature.geometry.geometryType)

                            partEdit = polylineBuild.parts.part(0)


                            console.log("OID to edit: " + updatingFeature.attributes.attributeValue("OBJECTID"))
                            console.log('updating feature geometry: ' + updatingFeature.geometry.geometryType)
                        }

                        // If last edit date is not today
                        else {
                            console.log("Dates are not the same: " + today+", editDate: "+editDate + ", creating new feature")
                            newFeature = true

                            updatingFeature = features[0]







                        }
                    }
                }
            }
        }



        Rectangle {
            id: rect
            anchors.fill: parent
            visible: autoPanListView.visible
            color: "black"
            opacity: 0.7
        }

        ListView {
            id: autoPanListView
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 10 * scaleFactor
            }
            visible: false
            width: parent.width
            height: 300 * scaleFactor
            spacing: 10 * scaleFactor
            model: ListModel {
                id: autoPanListModel
            }

            delegate: Row {
                id: autopanRow
                anchors.right: parent.right
                spacing: 10

                Text {
                    text: name
                    font.pixelSize: 25 * scaleFactor
                    color: "white"
                    MouseArea {
                        anchors.fill: parent
                        // When an item in the list view is clicked
                        onClicked: {
                            autopanRow.updateAutoPanMode();
                        }
                    }
                }

                Image {
                    source: image
                    width: 40 * scaleFactor
                    height: width
                    MouseArea {
                        anchors.fill: parent
                        // When an item in the list view is clicked
                        onClicked: {
                            autopanRow.updateAutoPanMode();
                        }
                    }
                }

                // set the appropriate auto pan mode
                function updateAutoPanMode() {
                    switch (name) {
                    case trackMode:
                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeNavigation ;
                        mapView.locationDisplay.start();
                        if (posSource.active === true) {
                            trackingNotification.schedule(notifTitle,"Satellite tracking active", notifTime)
                            app.locText = "Starting Tracking"
                            console.log("Starting Tracking")
                        }
                        break;
                    case stopMode:
                        mapView.locationDisplay.stop();
                        break;
                    }

                    if (name !== closeMode) {
                        currentModeText = name;
                        currentModeImage = image;
                    }
                    // hide the list view
                    currentAction.visible = true;
                    autoPanListView.visible = false;
                }
            }
        }

        Row {
            id: currentAction
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 25 * scaleFactor
            }
            spacing: 10

            Text {
                text: currentModeText
                font.pixelSize: 25 * scaleFactor
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        currentAction.visible = false;
                        autoPanListView.visible = true;
                    }
                }
            }

            Image {
                source: currentModeImage
                width: 40 * scaleFactor
                height: width
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        currentAction.visible = false;
                        autoPanListView.visible = true;
                    }
                }
            }
        }
    }

    // sample ends here ------------------------------------------------------------------------
    Controls.DescriptionPage{
        id:descPage
        visible: false
    }
}


