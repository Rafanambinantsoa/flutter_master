import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_master/config/api_config.dart';
import 'dart:async';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final _eventController = StreamController<PusherEvent>.broadcast();
  final Set<String> _activeChannels = {}; // Track active subscriptions
  bool _isPusherClientInitialized =
      false; // Flag to prevent multiple native client initializations

  Stream<PusherEvent> get events => _eventController.stream;

  Future<void> initPusher() async {
    if (_isPusherClientInitialized) {
      print(
        'DEBUG PusherService: Pusher client already initialized. Skipping init.',
      );
      return;
    }

    print('DEBUG PusherService: Initializing Pusher...');
    _activeChannels.clear(); // Clear active subscriptions on init
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
    _isPusherClientInitialized = true; // Mark as initialized

    await pusher.connect();
    print('DEBUG PusherService: Pusher connected.');
    await _subscribe(
      'commandes',
    ); // Subscribe to the main channel after connection
  }

  Future<void> _subscribe(String channelName) async {
    if (_activeChannels.contains(channelName)) {
      print(
        'DEBUG PusherService: Already subscribed to $channelName. Skipping.',
      );
      return;
    }
    print('DEBUG PusherService: Subscribing to channel: $channelName');
    await pusher.subscribe(channelName: channelName);
    _activeChannels.add(channelName);
  }

  Future<void> _unsubscribe(String channelName) async {
    print('DEBUG PusherService: Unsubscribing from channel: $channelName');
    await pusher.unsubscribe(channelName: channelName);
    _activeChannels.remove(channelName);
  }

  Future<void> disconnect() async {
    print('DEBUG PusherService: Disconnecting Pusher.');
    await pusher.disconnect();
    _isPusherClientInitialized = false; // Reset initialization flag
  }
}
