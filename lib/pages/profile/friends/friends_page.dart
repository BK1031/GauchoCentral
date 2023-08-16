// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:badges/badges.dart' as badges;
import 'package:extended_image/extended_image.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/friend.dart';
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/alert_service.dart';
import 'package:storke_central/utils/auth_service.dart';
import 'package:storke_central/utils/logger.dart';
import 'package:storke_central/utils/theme.dart';

import '../../../utils/config.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  int currPage = 0;
  PageController pageController = PageController();

  List<String> loadingList = [];
  bool refreshing = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    updateUserFriendsList();
  }

  Future<void> updateUserFriendsList() async {
    Trace trace = FirebasePerformance.instance.newTrace("updateUserFriendsList()");
    await trace.start();
    setState(() => refreshing = true);
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      log("[friends_page] Successfully updated local friend list");
      friends.clear();
      requests.clear();
      var responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      for (int i = 0; i < responseJson["data"].length; i++) {
        Friend friend = Friend.fromJson(responseJson["data"][i]);
        if (friend.status == "REQUESTED") {
          requests.add(friend);
        } else if (friend.status == "ACCEPTED") {
          friends.add(friend);
        }
      }
      setState(() {
        friends.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        requests.sort((a, b) => a.toUserID == currentUser.id ? -1 : 1);
      });
    } else {
      log("[friends_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to update friends list!");
    }
    setState(() => refreshing = false);
    trace.stop();
  }

  Future<User> getFriend(String id) async {
    Trace trace = FirebasePerformance.instance.newTrace("getFriend()");
    await trace.start();
    User user = User();
    await AuthService.getAuthToken();
    var response = await http.get(Uri.parse("$API_HOST/users/$id"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"});
    if (response.statusCode == 200) {
      user = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes))["data"]);
    } else {
      log("[friends_page] Failed to retrieve friend with id: $id", LogLevel.error);
      log("[friends_page] ${response.body}", LogLevel.error);
      AlertService.showErrorSnackbar(context, "Failed to get friend profile!");
    }
    log("[friends_page] Retrieved user info for: ${user.toString()}");
    trace.stop();
    return user;
  }

  Future<void> acceptFriend(User user) async {
    Trace trace = FirebasePerformance.instance.newTrace("acceptFriend()");
    await trace.start();
    Friend friend = requests.where((element) => element.fromUserID == user.id).first;
    friend.status = "ACCEPTED";
    setState(() {
      loadingList.add(friend.id);
    });
    await AuthService.getAuthToken();
    var response = await http.post(Uri.parse("$API_HOST/users/${currentUser.id}/friends"), headers: {"SC-API-KEY": SC_API_KEY, "Authorization": "Bearer $SC_AUTH_TOKEN"}, body: jsonEncode(friend));
    if (response.statusCode == 200) {
      log("[friends_page] Friend request accepted!");
      setState(() {
        requests.removeWhere((element) => element.id == friend.id);
        friends.add(friend);
      });
      updateUserFriendsList();
      // ignore: use_build_context_synchronously
      AlertService.showSuccessSnackbar(context, "You are now friends with ${friend.user.firstName}!");
    } else {
      log("[friends_page] ${response.body}", LogLevel.error);
      // ignore: use_build_context_synchronously
      AlertService.showErrorSnackbar(context, "Failed to send friend request");
    }
    setState(() {
      loadingList.remove(friend.id);
    });
    trace.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "Friends",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
            child: Card(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 0 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 0;
                        });
                        pageController.animateToPage(0, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                      },
                      child: Text("My Friends", style: TextStyle(color: currPage == 0 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: currPage == 1 ? SB_NAVY : null,
                      onPressed: () {
                        setState(() {
                          currPage = 1;
                        });
                        pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                      },
                      child: badges.Badge(
                        position: badges.BadgePosition.topEnd(top: -10, end: -20),
                        showBadge: requests.where((element) => element.fromUserID != currentUser.id).isNotEmpty,
                        badgeContent: Text(requests.where((element) => element.fromUserID != currentUser.id).length.toString(), style: const TextStyle(color: Colors.white)),
                        child: Text("Requests", style: TextStyle(color: currPage == 1 ? Colors.white : Theme.of(context).textTheme.button!.color)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: PageView(
                controller: pageController,
                onPageChanged: (int page) {
                  setState(() {
                    currPage = page;
                  });
                },
                children: [
                  Column(
                    children: [
                      Visibility(
                        visible: refreshing,
                        child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Center(child: RefreshProgressIndicator(backgroundColor: SB_NAVY, color: Colors.white,))
                        ),
                      ),
                      friends.isEmpty ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.person_crop_circle_badge_xmark,
                                size: 100,
                                color: Theme.of(context).textTheme.bodySmall!.color,
                              ),
                              const Padding(padding: EdgeInsets.all(4)),
                              const Text("No friends 😔", style: TextStyle(fontSize: 16),),
                            ],
                          ),
                        ),
                      ) : Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: InkWell(
                                onTap: () {
                                  router.navigateTo(context, "/profile/user/${friends[index].user.id}", transition: TransitionType.native);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        child: ExtendedImage.network(
                                          friends[index].user.profilePictureURL,
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.all(Radius.circular(125)),
                                          shape: BoxShape.rectangle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${friends[index].user.firstName} ${friends[index].user.lastName}",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            Text(
                                              "@${friends[index].user.userName}",
                                              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall!.color),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  refreshing ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: RefreshProgressIndicator())
                  ) :  requests.isEmpty ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle_badge_xmark,
                            size: 100,
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                          const Padding(padding: EdgeInsets.all(4)),
                          const Text("No friend requests"),
                        ],
                      ),
                    ),
                  ) : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: InkWell(
                          onTap: () {
                            router.navigateTo(context, "/profile/user/${requests[index].user.id}", transition: TransitionType.native);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: ExtendedImage.network(
                                    requests[index].user.profilePictureURL,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.all(Radius.circular(125)),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${requests[index].user.firstName} ${requests[index].user.lastName}",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Text(
                                        "@${requests[index].user.userName}",
                                        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color),
                                      )
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: loadingList.contains(requests[index].id),
                                  child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Center(child: RefreshProgressIndicator(
                                        color: Colors.white,
                                        backgroundColor: SB_NAVY
                                      ))
                                  ),
                                ),
                                Visibility(
                                  visible: requests[index].fromUserID != currentUser.id && !loadingList.contains(requests[index].id),
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                    color: SB_NAVY,
                                    child: Row(
                                      children: const [
                                        Icon(Icons.person_add, color: Colors.white),
                                        Padding(padding: EdgeInsets.all(4)),
                                        Text("Accept", style: TextStyle(color: Colors.white),),
                                      ],
                                    ),
                                    onPressed: () {
                                      acceptFriend(requests[index].user);
                                    },
                                  ),
                                ),
                                Visibility(
                                  visible: requests[index].fromUserID == currentUser.id,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.only(left: 16, top: 4, right: 16, bottom: 4),
                                    color: Theme.of(context).colorScheme.background,
                                    child: Row(
                                      children: [
                                        Icon(Icons.how_to_reg, color: Theme.of(context).iconTheme.color),
                                        const Padding(padding: EdgeInsets.all(2)),
                                        Text("Requested", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
                                      ],
                                    ),
                                    onPressed: () {},
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
