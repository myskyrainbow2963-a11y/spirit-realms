# 四界灵契音效清单与 Godot 触发点

更新时间：2026-07-23

## 1. 已有音频资产

| 文件 | 类型 | 当前用途 | 状态 |
| --- | --- | --- | --- |
| `res://music/Moonlit Oath.mp3` | BGM | 首页、云栖小筑 | 已接入 |
| `res://music/Glass Orbit.mp3` | BGM | 四界舆图、灵契图鉴 | 已接入 |
| `res://music/Crimson Resolve.mp3` | BGM | 使者界面 / 界域页面 | 已接入 |
| `res://music/Crimson Sky Duel.mp3` | BGM | 竞技场战斗 | 已接入 |
| `res://music/树木燃烧火焰声.mp3` | 环境声 | 魔界 / 使者界面火焰氛围 | 已接入 |
| `res://music/fire-onset-1-386711.mp3` | SFX | 四界舆图选择入口 | 已接入 |
| `res://music/火焰燃起声.mp3` | SFX | 进入云栖小筑、开始孵化 | 已接入 |
| `res://music/发射元素火焰中.mp3` | SFX | 竞技场出牌攻击起手 | 已接入 |
| `res://music/发射元素火焰强.mp3` | SFX | 竞技场命中、孵化揭示卡牌 | 已接入 |
| `res://music/发射火焰弱.mp3` | SFX | 火焰弱攻击 / 小点击候选 | 未接入 |

## 2. 已接入的 Godot 触发点

| 场景脚本 | 函数 / 触发点 | 音频 |
| --- | --- | --- |
| `audio_director.gd` | `play_music()` | 全局 BGM 播放入口 |
| `audio_director.gd` | `play_ambience()` | 全局循环环境声入口 |
| `audio_director.gd` | `play_sfx()` | 全局短音效入口 |
| `landing.gd` | `_ready()` | 播放 `Moonlit Oath.mp3`，停止环境声 |
| `world_choice.gd` | `_ready()` | 播放 `Glass Orbit.mp3`，停止环境声 |
| `world_choice.gd` | `_input()` 选中四界入口 | 播放 `fire-onset-1-386711.mp3` |
| `demon_realm.gd` | `_ready()` | 播放 `Crimson Resolve.mp3` 和 `树木燃烧火焰声.mp3` |
| `demon_realm.gd` | `_start_transition()` | 播放 `火焰燃起声.mp3` |
| `cloud_roost.gd` | `_ready()` | 播放 `Moonlit Oath.mp3`，停止环境声 |
| `cloud_roost.gd` | `_ready()` 检测孵化刚开始 | 播放 `火焰燃起声.mp3` |
| `cloud_roost.gd` | `_ready()` 检测孵化完成揭卡 | 播放 `发射元素火焰强.mp3` |
| `spirit_codex.gd` | `_ready()` | 播放 `Glass Orbit.mp3`，停止环境声 |
| `battle.gd` | `_ready()` | 播放 `Crimson Sky Duel.mp3`，停止环境声 |
| `battle.gd` | `_play_attack()` | 播放 `发射元素火焰中.mp3` |
| `battle.gd` | `_resolve_player_attack()` | 播放 `发射元素火焰强.mp3` |

## 3. 缺失音效与建议触发点

### 通用 UI

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 鼠标悬停轻响 | `ui_hover_chime.ogg` | 各脚本 `_input(event is InputEventMouseMotion)`，当 hover 目标变化时播放 |
| 普通点击 | `ui_click_soft.ogg` | 导航按钮、返回按钮、确认按钮点击 |
| 禁用 / 不能点击 | `ui_disabled.ogg` | 能量不足、按钮不可用、孵化未完成 |
| 页面切换呼吸音 | `ui_scene_whoosh.ogg` | `landing.gd::_leave()`、各页面 `change_scene_to_file` 前 |
| 后台 F10 打开 | `admin_open.ogg` | 各脚本 KEY_F10 分支 |
| 后台滑杆调整 | `admin_slider_tick.ogg` | `admin.gd` slider `value_changed` |
| 后台一键完成 | `admin_complete.ogg` | `admin.gd::_complete_hatch()` |

### 首页与剧情

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 首页进场晨雾 / 风铃 | `landing_intro_bells.ogg` | `landing.gd::_ready()` 或首次进入时 |
| 点击“踏入四界” | `landing_enter_gate.ogg` | `landing.gd::_input()` 主按钮 |
| 老者出现 | `elder_appear.ogg` | `elder.gd::_ready()` |
| 老者对白文字音 | `dialogue_type_soft.ogg` | `elder.gd` 对白出现时，可做循环短 tick |
| 接受委托 | `quest_accept.ogg` | `elder.gd::_input()` 命中 `ACCEPT` |

### 四界舆图

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 四个入口悬停共鸣 | `realm_gate_hover.ogg` | `world_choice.gd::_input()` hover 从 -1 变成入口 index |
| 人界入口 | `realm_human_enter.ogg` | `world_choice.gd::_input()` index 0 |
| 魔界入口 | `realm_demon_enter.ogg` | `world_choice.gd::_input()` index 1，目前临时用 fire onset |
| 仙界入口 | `realm_celestial_enter.ogg` | `world_choice.gd::_input()` index 2 |
| 冥界入口 | `realm_underworld_enter.ogg` | `world_choice.gd::_input()` index 3 |

### 使者与领蛋

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 使者登场 | `messenger_reveal.ogg` | `demon_realm.gd::_ready()` |
| 使者对白 | `messenger_voice_pad.ogg` | `demon_realm.gd::_draw_envoy_panel()` 首次显示时应由状态控制播放 |
| 灵兽蛋落入祭台 | `egg_land_on_altar.ogg` | `demon_realm.gd::_ready()` 或首次进入该界域 |
| 点击“返回云栖小筑” | `take_egg_return_home.ogg` | `demon_realm.gd::_start_transition("home")` |

### 云栖小筑 / 孵化

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 云栖小筑环境声 | `cloud_roost_ambience.ogg` | `cloud_roost.gd::_ready()`，可替代 stop ambience |
| 点击蛋 / 祭坛 | `altar_focus.ogg` | `cloud_roost.gd::_input()` 命中蛋或祭坛 |
| 选择智力 | `train_intelligence.ogg` | `cloud_roost.gd::_input()` 选择 skill `智力` |
| 选择体力 | `train_strength.ogg` | `cloud_roost.gd::_input()` 选择 skill `体力` |
| 选择灵力 | `train_spirit.ogg` | `cloud_roost.gd::_input()` 选择 skill `灵力` |
| 选择魔力 | `train_magic.ogg` | `cloud_roost.gd::_input()` 选择 skill `魔力` |
| 选择耐力 | `train_endurance.ogg` | `cloud_roost.gd::_input()` 选择 skill `耐力` |
| 确认修炼 | `training_confirm.ogg` | `cloud_roost.gd::_input()` 确认修炼按钮 |
| 孵化倒计时轻脉冲 | `hatch_pulse_loop.ogg` | `cloud_roost.gd` training active 时低音量循环 |
| 蛋挣扎 | `egg_wobble.ogg` | 孵化完成动画开头 |
| 破壳裂纹 | `egg_crack_01.ogg`、`egg_crack_02.ogg` | 孵化动画 crack 阶段 |
| 烟花飘落 | `hatch_fireworks_fall.ogg` | 孵化动画 fireworks 阶段 |
| 变成完整卡牌 | `card_manifest_full.ogg` | 孵化动画 reveal card 阶段 |

### 灵契图鉴

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 卡牌悬停 | `card_hover_glow.ogg` | `spirit_codex.gd::_input()` hover 卡牌变化 |
| 选择卡牌 | `card_select.ogg` | `spirit_codex.gd::_input()` 设置 `selected` |
| 打开素材图鉴 | `gallery_open.ogg` | `spirit_codex.gd::_input()` 命中 `GALLERY_BUTTON` |
| 图鉴翻页 / 切换 | `codex_page_turn.ogg` | 后续若加入分页时 |
| 进入竞技场 | `arena_enter.ogg` | `spirit_codex.gd::_leave("res://battle.tscn")` |

### 竞技场

| 需要的音效 | 建议文件名 | 建议触发点 |
| --- | --- | --- |
| 抽牌 | `battle_draw_card.ogg` | 后续做抽牌堆机制时，每抽一张 |
| 弃牌 | `battle_discard.ogg` | `battle.gd::_end_turn()` |
| 选择手牌 | `battle_card_pick.ogg` | `battle.gd::_select_card()` |
| 出牌飞出 | `battle_card_cast.ogg` | `battle.gd::_play_attack()` 或技能牌分支 |
| 能量不足 | `battle_no_energy.ogg` | `battle.gd::_select_card()` cost > energy |
| 防御加格挡 | `battle_block_gain.ogg` | `battle.gd::_select_card()` skill 分支 |
| 玩家普通命中 | `battle_player_hit.ogg` | `battle.gd::_resolve_player_attack()` |
| 敌人受击 | `enemy_hit_flesh.ogg` | `battle.gd::_resolve_player_attack()` |
| 敌人格挡 | `enemy_block_gain.ogg` | `battle.gd::_run_enemy_step()` intent defend |
| 敌人攻击起手 | `enemy_attack_windup.ogg` | `battle.gd::_run_enemy_step()` intent attack |
| 敌人命中玩家 | `player_hit.ogg` | `battle.gd::_run_enemy_step()` 结算伤害 |
| 玩家获得减益 | `player_debuff.ogg` | `battle.gd::_run_enemy_step()` intent debuff |
| 敌人死亡 | `enemy_defeated.ogg` | `battle.gd::_resolve_player_attack()` hp <= 0 |
| Boss 登场 | `boss_intro_roar.ogg` | `battle.gd::_ready()` 或 Boss 第一次显示 |
| Boss 大招预警 | `boss_intent_danger.ogg` | Boss intent 为 attack 且 value 高时 |
| 回合开始 | `turn_start.ogg` | 后续抽牌回合开始函数 |
| 结束回合 | `turn_end.ogg` | `battle.gd::_end_turn()` |
| 胜利 | `battle_victory.ogg` | 所有敌人 hp <= 0 时 |
| 失败 | `battle_defeat.ogg` | `player_hp <= 0` 时 |
| 认输 | `battle_surrender.ogg` | `battle.gd::_surrender()` |

## 4. 推荐优先补齐顺序

1. UI 点击、悬停、禁用：立刻改善“有反应”的手感。
2. 孵化三段：蛋挣扎、破壳、完整卡牌显现，是当前游戏最重要的仪式感。
3. 战斗基础：抽牌、出牌、格挡、受击、敌人死亡、胜利、失败。
4. 四界差异：人界、魔界、仙界、冥界入口和环境声各自独立。
5. 剧情对白：老者、使者、委托确认，让开场流程更像商业游戏。

## 5. 命名规则

新音效建议统一放在 `res://music/`，文件名使用英文小写加下划线，格式优先 `ogg`，例如：

`battle_card_pick.ogg`

这样 Godot 导入更稳定，也避免中文文件名在不同系统或导出平台上出问题。
