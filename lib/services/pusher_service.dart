import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_master/config/api_config.dart';
import 'dart:async';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final _eventController = StreamController<PusherEvent>.broadcast();

  Stream<PusherEvent> get events => _eventController.stream;

  Future<void> initPusher() async {
    await pusher.init(
      apiKey: ApiConfig.pusherApiKey,
      cluster: ApiConfig.pusherCluster,
      onConnectionStateChange: (currentState, previousState) {
        print('Pusher state: $previousState -> $currentState');
      },
      onError: (message, code, error) {
        print('Pusher error: $message ($code)');
      },
      onEvent: (event) {
        print('Event reçu: ${event.channelName} | ${event.eventName}');
        print('Data: ${event.data}');
        _eventController.add(event);
      },
    );

    await pusher.connect();
  }

  Future<void> subscribe(String channelName) async {
    await pusher.subscribe(channelName: channelName);
  }

  Future<void> unsubscribe(String channelName) async {
    await pusher.unsubscribe(channelName: channelName);
  }

  Future<void> disconnect() async {
    await pusher.disconnect();
  }
}
