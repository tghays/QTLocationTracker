# QTLocationTracker
Test Application to track an AGOL or ArcGIS Portal user's location using a Feature Service.

The Application was built using ArcGIS AppStudio, written in Qt using the ArcGIS Runtime SDK Qt QML.  The application supports AGOL and Portal login, and allows the user to toggle location tracking on and off.  The device will send updates to the associated Feature Service on the user's organization AGOL or Portal for ArcGIS, and will only update if the user's device has moved more than a specified distance and a specified time has passed.  The feature service the application writes to is a line feature, created for the user for the day if the user has not yet logged in that day. 

An associated web interface can pull the feature service in using the ArcGIS Javascript API to view the live updates to the feature service that the mobile tracker application is syncing.

Since Qt was used to write the application, it can be used on both Android and iOS devices.

Login Screen
![Login](https://github.com/tghays/QTLocationTracker/blob/master/login.png | height = 200)

Welcome Screen
![Welcome](https://github.com/tghays/QTLocationTracker/blob/master/welcome.png | height = 200)
