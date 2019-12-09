/******************************************************************************
 * Copyright © 2013-2019 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

#pragma once

#include <thread>
#include <folly/concurrency/ConcurrentHashMap.h>
#include <antara/gaming/ecs/system.hpp>
#include "atomic.dex.events.hpp"
#include "atomic.dex.utilities.hpp"

namespace atomic_dex {
    namespace ag = antara::gaming;

    class coinpaprika_provider final : public ag::ecs::pre_update_system<coinpaprika_provider> {
        //! use it like map.at(USD).at("BTC"); returns "8000" dollars for 1 btc
        using providers_registry = folly::ConcurrentHashMap<std::string, std::string>;
        using fiat_provider_registry = folly::ConcurrentHashMap<std::string, providers_registry>;
        fiat_provider_registry rate_providers_;
        std::unordered_set<std::string> supported_fiat_{"USD", "EUR"};
        std::thread provider_rates_thread_;
        timed_waiter provider_thread_timer_;
    public:
        coinpaprika_provider(entt::registry &registry);
        ~coinpaprika_provider() noexcept final;
        void on_mm2_started(const atomic_dex::mm2_started &evt) noexcept;
        void update() noexcept final;
    };
}

REFL_AUTO(type(atomic_dex::coinpaprika_provider))