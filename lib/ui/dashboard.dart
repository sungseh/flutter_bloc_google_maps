import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtbuddy/blocs/dashboard/dashboard_bloc.dart';
import 'package:gtbuddy/blocs/dashboard/dashboard_event.dart';
import 'package:gtbuddy/blocs/dashboard/dashboard_state.dart';
import 'package:gtbuddy/blocs/map/map_bloc.dart';
import 'package:gtbuddy/blocs/map/map_event.dart';
import 'package:gtbuddy/services/dashboard_saved_stations.dart';
import 'package:gtbuddy/ui/map.dart';
import 'package:gtbuddy/ui/tiles/dashboard_header_tile.dart';
import 'package:gtbuddy/ui/tiles/dashboard_result_tile.dart';
import 'package:gtbuddy/ui/tiles/loading.dart';
import 'package:gtbuddy/utils/colour_pallete.dart';
import 'package:gtbuddy/utils/text_style.dart';

import 'locations_list.dart';
import 'map.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bus Routes"),
        centerTitle: true,
        backgroundColor: Pallete.appBarColor,
        actions: <Widget>[
          FlatButton(
            textColor: Pallete.White,
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => LocList()));
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
      body: BlocProvider(
        create: (ctx) => DashboardSavedBloc(),
        child: Saved(),
      ),
    );
  }
}

class Saved extends StatefulWidget {
  @override
  SavedState createState() => SavedState();
}

class SavedState extends State<Saved> {
  DashboardSavedBloc _dashboardSavedBloc;

  @override
  void initState() {
    super.initState();
    _dashboardSavedBloc = BlocProvider.of<DashboardSavedBloc>(context);
    _dashboardSavedBloc.add(LoadSaved());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<DashboardSavedBloc, DashboardSavedState>(
        builder: (context, state) {
          if (state is Initial) {
            print('Uninitialized');
            return CustomLoading();
          } else if (state is SavedLoading) {
            print('loading...');
            return CustomLoading();
          } else if (state is SavedLoaded) {
            print('loaded');
            return ListBuilder(state.savedStations, state.closest);
          } else if (state is SavedNotLoaded) {
            print('Problem');
            return CustomLoading();
          } else if (state is SavedLoaded) {
            print('Problem');
            return CustomLoading();
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dashboardSavedBloc.drain();
  }
}

/*
TODO:
1. Cater for empty saved stations. Display message "No saved stations yet"
2.
 */

class ListBuilder extends StatelessWidget {
  final List<String> _savedStations;
  final Map<String, dynamic> _closest;

  ListBuilder(this._savedStations, this._closest);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Pallete.BarHeadColor,
      child: Column(
        children: <Widget>[
          DashboardTile("SAVED STATIONS", 50.0),
          _savedStations != null && _savedStations.length > 0
              ? Container(
                  height: 180,
                  color: Pallete.BackgroundColour,
                  child: ListView.separated(
                    separatorBuilder: (context, index) => Divider(),
                    itemCount:
                        _savedStations != null ? _savedStations.length : 0,
                    itemBuilder: (BuildContext context, int index) {
                      print(_savedStations.length);
                      return Dismissible(
                        key: Key(_savedStations[index]),
                        onDismissed: (direction) {
                          _savedStations.removeAt(index);
                          SavedService().deleteSavedStation(index);
                          Scaffold.of(context).showSnackBar(
                              new SnackBar(content: Text("Station Removed")));
                          Navigator.pushReplacement(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => HomeScreen()));
                        },
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Pallete.Red,
                          child: Icon(Icons.delete, color: Pallete.White),
                        ),
                        child: FutureBuilder(
                            future: SavedService()
                                .selectGeoBusStation(_savedStations[index]),
                            builder: (ctx, asyncSnapShot) {
                              return GestureDetector(
                                onTap: () {
                                  BlocProvider.of<MapBloc>(context).add(
                                    GetMapLocations(
                                        selectStation: _savedStations[index],
                                        selectCoords: _savedStations[index],
                                      initialLat:
                                          asyncSnapShot.data['latitude'],
                                      initialLong:
                                          asyncSnapShot.data['longitude'],
                                        ),
                                  );

                                  Navigator.pushReplacement(
                                      context,
                                      new MaterialPageRoute(
                                          builder: (context) => GoogleMapp(
                                              _savedStations[index],asyncSnapShot.data['latitude'], asyncSnapShot.data['longitude'] )));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.only(left: 12),
                                        alignment: Alignment.centerLeft,
                                        child: Text(_savedStations[index],
                                            style: AppStyles.Results()),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      );
                    },
                  ),
                )
              : Container(
                  height: 180,
                  color: Pallete.BackgroundColour,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 12, top: 32),
                          alignment: Alignment.center,
                          child: Text(
                              "You dont have any saved routes. Add routes by selecting the add button in the top right corner.",
                              style: AppStyles.Results()),
                        ),
                      ],
                    ),
                  )),
          DashboardTile("CLOSEST STATIONS", 50.0),
          Container(
            height: 40,
            color: Pallete.White,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: GestureDetector(
              onTap: () {
                print(_closest['short_name']);

                BlocProvider.of<MapBloc>(context).add(
                  GetMapLocations(
                    selectStation: _closest['short_name'],
                    selectCoords: _closest['short_name'],
                    initialLat: _closest['latitude'],
                    initialLong: _closest['longitude'],
                  ),
                );
                Navigator.pushReplacement(
                    context,
                    new MaterialPageRoute(
                        builder: (context) =>
                            GoogleMapp(_closest['short_name'],_closest['latitude'], _closest['longitude'])));
              },
              child: Text(_closest['short_name'], style: AppStyles.Results()),
            ),
          ),
          DashboardTile("ALL STATIONS", 50.0),
      Container(
        height: 40,
        alignment: Alignment.centerLeft,
        color: Pallete.BarColor,
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            BlocProvider.of<MapBloc>(context).add(
              GetMapLocations(
                selectStation: "All",
                selectCoords: "All",
                initialLat: 0.0,
                initialLong: 0.0,
              ),
            );
            Navigator.pushReplacement(
                context,
                new MaterialPageRoute(
                    builder: (context) =>
                        GoogleMapp('All stations',0.0, 0.0)));


          },
          child: Text("All stations", style: AppStyles.Results()),
        ),
      )
        ],
      ),
    );
  }
}
