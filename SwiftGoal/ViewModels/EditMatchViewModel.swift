//
//  EditMatchViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 22/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa

public class EditMatchViewModel {

    // Inputs
    public let homeGoals: MutableProperty<Int>
    public let awayGoals: MutableProperty<Int>

    // Outputs
    public let title: String
    public let formattedHomeGoals = MutableProperty<String>("")
    public let formattedAwayGoals = MutableProperty<String>("")
    public let homePlayersString = MutableProperty<String>("")
    public let awayPlayersString = MutableProperty<String>("")
    public let inputIsValid = MutableProperty<Bool>(false)

    // Actions
    lazy var saveAction: Action<Void, Bool, NSError> = { [unowned self] in
        return Action(enabledIf: self.inputIsValid, { _ in
            let parameters = MatchParameters(
                homePlayers: self.homePlayers.value,
                awayPlayers: self.awayPlayers.value,
                homeGoals: self.homeGoals.value,
                awayGoals: self.awayGoals.value
            )
            if let match = self.match {
                return self.store.updateMatch(match, parameters: parameters)
            } else {
                return self.store.createMatch(parameters)
            }
        })
    }()

    private let store: Store
    private let match: Match?
    private let homePlayers: MutableProperty<Set<Player>>
    private let awayPlayers: MutableProperty<Set<Player>>

    // MARK: Lifecycle

    public init(store: Store, match: Match?) {
        self.store = store
        self.match = match

        // Set properties based on whether an existing match was passed
        self.title = (match != nil ? "Edit Match" : "New Match")
        self.homePlayers = MutableProperty(Set<Player>(match?.homePlayers ?? []))
        self.awayPlayers = MutableProperty(Set<Player>(match?.awayPlayers ?? []))
        self.homeGoals = MutableProperty(match?.homeGoals ?? 0)
        self.awayGoals = MutableProperty(match?.awayGoals ?? 0)

        self.formattedHomeGoals <~ homeGoals.producer |> map { goals in return "\(goals)" }
        self.formattedAwayGoals <~ awayGoals.producer |> map { goals in return "\(goals)" }

        self.homePlayersString <~ homePlayers.producer
            |> map { players in
                return players.isEmpty ? "Set Home Players" : ", ".join(map(players, { $0.name }))
            }
        self.awayPlayersString <~ awayPlayers.producer
            |> map { players in
                return players.isEmpty ? "Set Away Players" : ", ".join(map(players, { $0.name }))
            }
        self.inputIsValid <~ combineLatest(homePlayers.producer, awayPlayers.producer)
            |> map { (homePlayers, awayPlayers) in
                return !homePlayers.isEmpty && !awayPlayers.isEmpty
            }
    }

    public convenience init(store: Store) {
        self.init(store: store, match: nil)
    }

    // MARK: View Models

    public func manageHomePlayersViewModel() -> ManagePlayersViewModel {
        let homePlayersViewModel = ManagePlayersViewModel(
            store: store,
            initialPlayers: homePlayers.value,
            disabledPlayers: awayPlayers.value
        )
        self.homePlayers <~ homePlayersViewModel.selectedPlayers

        return homePlayersViewModel
    }

    public func manageAwayPlayersViewModel() -> ManagePlayersViewModel {
        let awayPlayersViewModel = ManagePlayersViewModel(
            store: store,
            initialPlayers: awayPlayers.value,
            disabledPlayers: homePlayers.value
        )
        self.awayPlayers <~ awayPlayersViewModel.selectedPlayers

        return awayPlayersViewModel
    }
}
