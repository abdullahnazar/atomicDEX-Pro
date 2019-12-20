import os, osproc
import marshal
import json
import hashes
import threadpool
import ./worker
import ../gui/gui
import ../utils/assets
import ../coins/coins_cfg
import ../folly/hashmap
import ./api

type
    MM2Config = object
        gui: string
        netid: int64
        userhome: string
        passphrase: string
        rpc_password: string

var mm2_cfg : MM2Config = MM2Config(gui: "MM2GUI", netid: 9999, userhome: os.getHomeDir(), passphrase: "thisIsTheNewProjectSeed2019##", rpc_password: "atomic_dex_rpc_password")
var mm2_instance : Process = nil

proc set_passphrase*(passphrase: string) =
    mm2_cfg.passphrase = passphrase

proc mm2_init_thread() =
    {.gcsafe.}:
        var tools_path = (get_assets_path() & "/tools/mm2").normalizedPath
        try: 
            mm2_instance = startProcess(command=tools_path & "/mm2", args=[$$mm2_cfg], env = nil, options={poParentStreams}, workingDir=tools_path)
        except OSError as e:
            echo "Got exception OSError with message ", e.msg
        finally:
            echo "Fine."
        sleep(2000)
        gui.set_gui_running(true)


proc enable_coin*(ticker: string) =
    {.gcsafe.}:
        var coin_info = coins_registry.cm_at(ticker.hash)
        if coin_info["currently_enabled"].getBool:
            return
        var res: seq[ElectrumServerParams]
        for keys in coin_info["electrum"]:
            res.add(ElectrumServerParams(keys))
        var req = create(ElectrumRequestParams, ticker, res, true)
        var answer = rpc_electrum(req)
    

proc enable_default_coins() =
    var coins = get_active_coins()
    for _, v in coins:
        spawn enable_coin(v["coin"].getStr)
    sync()    

proc init_process*()  =
    spawn mm2_init_thread()
    sync()
    enable_default_coins()
    launchMM2Worker()

proc close_process*() =
    if not mm2_instance.isNil:
        mm2_instance.terminate
        mm2_instance.close

    
