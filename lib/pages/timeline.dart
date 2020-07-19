import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:indiagram/models/user.dart';
import 'package:indiagram/pages/home.dart';
import 'package:indiagram/pages/search.dart';

import 'package:indiagram/widgets/header.dart';
import 'package:indiagram/widgets/post.dart';
import 'package:indiagram/widgets/progress.dart';

final usersRef = Firestore.instance.collection("users");

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  String currentUserId = currentUser?.id;
  List<String> followingList = [];

  @override
  void initState(){
    super.initState();
    _TimelineState();
    getFollowing();
  }

  getFollowing() async{
      QuerySnapshot snapshot = await followingRef
          .document(currentUser.id)
          .collection('userFollowing')
          .getDocuments();

      setState(() {
        followingList = snapshot.documents.map((doc) => doc.documentID)
            .toList();
      });
  }


  Future<List<String>> _getUserIds() async {
    List<String> userIds = [];
    QuerySnapshot snapshot = await timelineRef
        .document(currentUserId)
        .collection("userFollowing")
        .getDocuments();

//    print(snapshot.documents);
    snapshot.documents.forEach((doc) {
      userIds.add(doc.documentID);
    });


    return userIds;
  }

  Future<List<Post>> _getPosts() async{
    List<Post> posts = [];
    List<String> userIds = await _getUserIds();
    print(userIds);

    await Future.wait(userIds.map((uId) async{
      QuerySnapshot snapshot = await postsRef
          .document(uId)
          .collection('userPosts')
          .orderBy('timestamp', descending: true)
          .getDocuments();


        posts.addAll(snapshot.documents.map((doc) => Post.fromDocument(doc)).toList());

    }));

    print(posts);
    return posts;
  }


  buildUsersToFollow(){
    return StreamBuilder(
      stream: usersRef.orderBy('timestamp', descending: true).limit(30)
          .snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc){
          print(doc);
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          //remove current user from recommended list
          if(isAuthUser)
            {
              return ;
            }else if(isFollowingUser){
            return;
          }else
            {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }


        });
        return Container(
          color:Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                        Icons.person_add,
                        color: Theme.of(context).primaryColor,
                        size: 30.0,
                    ),
                    SizedBox(width: 8.0,),
                    Text(
                      "Users to Follow",
                      style: TextStyle(
                        color:  Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: header(context, isAppTitle: true),
      body: Container(
        child: FutureBuilder(
          future: _getPosts(),
          builder: (BuildContext context, AsyncSnapshot snapshot){
            if(!snapshot.hasData){
              return circularProgress();

            }
            else if(snapshot.hasData && snapshot.data.isEmpty)
              {
                return buildUsersToFollow();
              }
            else
              {
                return ListView(
                  children: snapshot.data,
                );
              }
          },
        ),
      ),
    );
  }
}
