/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart' hide Action;
import 'package:klient/screens/communication.dart';
import 'package:klient/screens/messages.dart';
import 'package:klient/widgets/communication_card.dart';
import 'package:morpheus/morpheus.dart';
import 'package:scolengo_api/scolengo_api.dart';

class MessagesSearchDelegate extends SearchDelegate {
  static MessageSearchResultsState? messageSearchSuggestionState;
  static String? searchQuery;

  @override
  String get searchFieldLabel => 'Recherche';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Vider',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return Center(
          child: Text('Entrez au moins 3 caractères',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary)));
    }
    searchQuery = query;
    if (MessagesSearchDelegate.messageSearchSuggestionState != null) {
      MessagesSearchDelegate.messageSearchSuggestionState!.refresh();
    }
    return const MessageSearchResults();
  }
}

class MessageSearchResults extends StatefulWidget {
  const MessageSearchResults({Key? key}) : super(key: key);

  @override
  State<MessageSearchResults> createState() => MessageSearchResultsState();
}

class MessageSearchResultsState extends State<MessageSearchResults> {
  List<Communication>? _communications;

  MessageSearchResultsState() {
    MessagesSearchDelegate.messageSearchSuggestionState = this;
    refresh();
  }

  refresh() {
    /* TODO rewrite this
     Conversation.search(MessagesSearchDelegate.searchQuery!).then((conversations) {
      if (!mounted) return;
      setState(() {
        _communications = conversations;
      });
    });
 */
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _communications == null
          ? const CircularProgressIndicator()
          : _communications!.isEmpty
              ? Text(
                  'Aucun résultat trouvé.',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  textAlign: TextAlign.center,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final parentKey = GlobalKey();
                      return InkWell(
                          child: Padding(
                            key: parentKey,
                            padding: const EdgeInsets.all(8.0),
                            child: CommunicationCard(
                              _communications![index],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MorpheusPageRoute(
                                transitionToChild: true,
                                builder: (_) => CommunicationPage(
                                  onDelete: deleteConversation,
                                  id: _communications![index].id,
                                  subject: _communications![index].subject,
                                ),
                                parentKey: parentKey,
                              ),
                            );
                          });
                    },
                    separatorBuilder: (context, index) {
                      return const Divider();
                    },
                    itemCount: _communications!.length,
                  ),
                ),
    );
  }
}
