import 'dart:math';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:sendbird_sdk/sendbird_sdk.dart' hide ConnectionState;

import 'package:testv_app/utils/shared_prefs.dart';

String generateRandomID(int length) {
  const randomChars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const randStringLength = 60; // length of _randomChars
  final rand = Random();
  final codeUnits = List.generate(length, (index) {
    int randIndex = rand.nextInt(randStringLength);
    return randomChars.codeUnitAt(randIndex);
  });
  return String.fromCharCodes(codeUnits);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs().init();
  if (SharedPrefs().id.isEmpty) {
    SharedPrefs().setId = (generateRandomID(10));
  }

  final sendbird = SendbirdSdk(appId: 'BC823AD1-FBEA-4F08-8F41-CF0D9D280FBF');
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false, home: MainApp(sendbird: sendbird)));
}

class MainApp extends StatefulWidget {
  final SendbirdSdk sendbird;

  const MainApp({Key? key, required this.sendbird}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with ChannelEventHandler {
  String message = '';
  String channelString =
      "sendbird_open_channel_14092_bf4075fbb8f12dc0df3ccc5c653f027186ac9211";
  final GroupChannel channel = GroupChannel(
      channelUrl:
          "sendbird_open_channel_14092_bf4075fbb8f12dc0df3ccc5c653f027186ac9211");

  final _messageTextController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final lastKey = GlobalKey();

  bool empty = false;

  Future<List<BaseMessage>>? _fetchCh;

  List<BaseMessage> _messages = [];

  Future<void> _connectUser() async {
    try {
      final user = await widget.sendbird.connect(
        SharedPrefs().id,
      );
      print('User connected: ${user.userId}');

      // _joinChannel();
    } catch (e) {
      print('Error connecting user: $e');
    }
  }

  Future<void> _joinChannel() async {
    try {
      final chan = await OpenChannel.getChannel(channelString);

      await chan.enter();

      print('Channel joined: ${chan.entered}');
      // setState(() {
      //   _fetchCh = getMessages(channel);
      // });
      _fetchCh = getMessages(channel);
      setState(() {});
      return;
    } catch (e) {
      if (e is BadRequestError) {
        print('Detailed Error: ${e.message}');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // _connectUser().then((value) {
    //   _joinChannel().then((_) {
    //     setState(() {
    //       _fetchCh = getMessages(channel);
    //     });
    //   });
    // });
    _connectUser().then((value) {
      _joinChannel().whenComplete(() {
        // setState(() {
        //   _fetchCh = getMessages(channel);
        // });
      });
    });
    SendbirdSdk().addChannelEventHandler(channelString, this);
  }

  @override
  void dispose() {
    SendbirdSdk().removeChannelEventHandler(channelString);
    super.dispose();
  }

  @override
  onMessageReceived(channel, message) {
    setState(() {
      _messages.add(message);
      _messages.sort(((a, b) => b.createdAt.compareTo(a.createdAt)));
    });
  }

  Future<List<BaseMessage>> getMessages(GroupChannel? channel) async {
    // print(_fetchCh);
    if (_fetchCh == null) {
      print("not there");

      return [];
    }
    print("fetch");
    try {
      List<BaseMessage> messages = await channel!.getMessagesByTimestamp(
          DateTime.now().millisecondsSinceEpoch * 1000, MessageListParams());
      messages.sort(((a, b) => b.createdAt.compareTo(a.createdAt)));
      print(messages.length);
      setState(() {
        messages.sort(((a, b) => b.createdAt.compareTo(a.createdAt)));
        _messages = messages;
      });
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        setState(() {});
      });
      return messages;
    } catch (e) {
      print('group_channel_view.dart: getMessages: ERROR: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    String? message,
  }) async {
    try {
      var sentMessage = channel.sendUserMessageWithText(message!);
      setState(() {
        _messages.add(sentMessage);
        _messages.sort(((a, b) => b.createdAt.compareTo(a.createdAt)));
      });
    } catch (error) {
      // The write failed...
      print(error);
    }
  }

  List<ChatMessage> asDashChatMessages(List<BaseMessage> messages) {
    // BaseMessage is a Sendbird class
    // ChatMessage is a DashChat class
    List<ChatMessage> result = [];
    if (messages.isNotEmpty) {
      messages.forEach((message) {
        User user = message.sender as User;
        if (user == null) {
          return;
        }
        result.add(
          ChatMessage(
            createdAt: DateTime.fromMillisecondsSinceEpoch(message.createdAt),
            text: message.message,
            user: asDashChatUser(user),
          ),
        );
      });
    }
    return result;
  }

  ChatUser asDashChatUser(User user) {
    return ChatUser(
      firstName: user.nickname,
      id: user.userId,
      profileImage: user.profileUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    ChatUser? user = SendbirdSdk().currentUser != null
        ? asDashChatUser(SendbirdSdk().currentUser!)
        : null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.grey[200],
          ),
          onPressed: () {},
        ),
        title: Text(
          "Home",
          style: TextStyle(
            color: Colors.grey[200],
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.grey[200],
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: FutureBuilder<List<BaseMessage>>(
                      future: _fetchCh,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const Center(
                              child: Text(
                                'Error loading messages',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            snapshot.connectionState == ConnectionState.none) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: SizedBox(
                                height: 26,
                                width: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.grey[200],
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }

                        // WidgetsBinding.instance.addPostFrameCallback((_) {
                        //   setState(() {});
                        // });

                        print(snapshot.data);

                        if (snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 82,
                                  width: 82,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(80),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.chat_bubble_2,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                Text(
                                  'No messages in this channel yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                    fontSize: 23,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                          );
                        }

                        // WidgetsBinding.instance.addPostFrameCallback((_) {
                        //   if (empty) {
                        //     setState(() {
                        //       empty = false;
                        //     });
                        //   }
                        //   if (_scrollController.hasClients) {
                        //     _scrollController.animateTo(
                        //       _scrollController.position.maxScrollExtent,
                        //       duration: const Duration(milliseconds: 400),
                        //       curve: Curves.fastOutSlowIn,
                        //     );
                        //   }
                        // });

                        return Wrap(
                          children: _messages
                              .map((BaseMessage message) {
                                // print(message.sender!.userId);
                                if (message.sender!.userId == user!.id) {
                                  // is current user
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7,
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          margin: const EdgeInsets.only(
                                            bottom: 13,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Color(0xffFF006A),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              topLeft: Radius.circular(25),
                                              bottomLeft: Radius.circular(25),
                                              bottomRight: Radius.circular(25),
                                            ),
                                          ),
                                          child: Text(
                                            message.message,
                                            style: TextStyle(
                                              color: Colors.grey[50],
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundImage: NetworkImage(
                                              message.sender!.profileUrl!),
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.5,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 20),
                                              margin: const EdgeInsets.only(
                                                bottom: 13,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[900],
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  topRight: Radius.circular(25),
                                                  bottomLeft:
                                                      Radius.circular(25),
                                                  bottomRight:
                                                      Radius.circular(25),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "Header",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500]),
                                                      ),
                                                      const SizedBox(
                                                        width: 4,
                                                      ),
                                                      const Icon(
                                                        Icons.circle,
                                                        size: 10,
                                                        color:
                                                            Colors.greenAccent,
                                                      )
                                                    ],
                                                  ),
                                                  Text(
                                                    message.message,
                                                    style: TextStyle(
                                                      color: Colors.grey[200],
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0, bottom: 10),
                                              child: Text(
                                                "Sub",
                                                style: TextStyle(
                                                    color: Colors.grey[500]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  );
                                }
                              })
                              .toList()
                              .reversed
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 5),
              child: Icon(
                Icons.add,
                color: Colors.grey[200],
                size: 34,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageTextController,
                onSubmitted: (value) async {
                  if (message.isNotEmpty) {
                    print(message);
                    await sendMessage(
                      message: message.trim(),
                    );
                    _messageTextController.clear();
                    setState(() {
                      message = '';
                    });
                  }
                },
                onChanged: (value) {
                  setState(() {
                    message = value.trim();
                  });
                },
                style: TextStyle(color: Colors.grey[50]),
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 16),
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    hintText: "Type in your message",
                    fillColor: const Color.fromRGBO(255, 255, 255, 0.102),
                    suffixIcon: Padding(
                      padding:
                          const EdgeInsets.only(right: 12.0, top: 5, bottom: 5),
                      child: GestureDetector(
                        onTap: () async {
                          if (message.isNotEmpty) {
                            print(message);
                            await sendMessage(
                              message: message.trim(),
                            );
                            _messageTextController.clear();
                            setState(() {
                              message = '';
                            });
                          }
                        },
                        child: Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 37,
                          color: message.isNotEmpty
                              ? const Color(0xffFF006A)
                              : Colors.grey[800],
                        ),
                      ),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
