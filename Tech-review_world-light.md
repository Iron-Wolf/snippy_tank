# World Light

This note describes how the battlefield tint and contact shadows are built,
why the implementation uses these mechanisms, and what went wrong with the
earlier scene-order approach.

## How the feature works

### Ambient tint

The existing `CanvasModulate` node, `WorldShadow`, provides an even tint across
the battlefield. `World.ambient_tint` is the normal color target; the existing
lightning effect temporarily overrides it and fades back to that target. This
is a uniform color treatment, not a directional light or a physically lit
scene.

### Sprite shadows

`World` listens to `SceneTree.node_added`. When an eligible `Sprite2D` enters
the tree under `%Map`, or directly under a `Player`, it creates a sibling
`SpriteShadow` proxy. Metadata marks the source and proxy so adding the proxy
does not recursively create more shadows.

The proxy follows its source's texture, frame or region, flips, transform,
visibility, and z-index. `shader/sprite_shadow.gdshader` samples the source
texture alpha to produce a tinted mask and soften its edges. The world settings
control its tint, opacity, direction, offset length, and softness. This is a
shifted 2D silhouette approximation: it does not calculate occlusion or cast
geometry-based shadows.

This discovery path covers level sprites and runtime sprites inside the map,
including power-ups, moving-wall segments, and dropped barrel parts. Player
sprites are covered separately because the players are direct children of
`World`, not children of `%Map`; this also covers duplicate players.
Sprite2D nodes elsewhere in the scene tree are not automatically shadowed.

### Obstacle tile shadows

Each `WallTileMap` creates a non-colliding child `TileMapLayer` called
`ShadowMask`, sharing the obstacle's tile set. It mirrors occupied cells,
including source IDs, atlas coordinates, and alternative tiles. Its child
transform applies the configured offset, and its relative z-index places it
behind the obstacle.

`WallTileMap._process()` removes shadow cells whose source cells were erased
and copies changed or newly occupied cells. This also handles tile edits made
by bullets and level scripts without requiring those callers to update a
second map. The cost is a per-frame scan of used cells on each wall tilemap.
Tile shadows are shifted tile art with atlas alpha, not separately generated
soft masks; the sprite softness setting does not blur them.

### Draw order

The intended layering is ground, shadow, then object. Obstacle tilemaps and
moving/dynamic obstacle bodies use z-index 2; each obstacle shadow layer is
relative z-index -1. Sprite proxies use a z-index one lower than their source.
Players keep their existing top-level z-index, and the UI remains above the
battlefield. The exact composite order depends on parent transforms and
`z_as_relative`, so changes to scene hierarchy or z-index settings should be
checked in the running project.

## Why this design

- **Named ground reference:** `World.get_background_tilemap()` now returns the
  cached `Map/BackTileMap/Background` node, refreshed when `_change_map()` loads
  a level. `Player` uses this tilemap for its arena/void check, and power-ups,
  barrel parts, and other gameplay code also query it. Keeping the established
  method while replacing its positional traversal avoids changing those
  callers. Level scenes need to provide the same named path.
- **No `DirectionalLight2D`:** its shadows are effectively parallel, while
  `max_distance` controls culling rather than shadow length. That does not
  provide the short, local contact effect wanted here.
- **Generated sprite masks:** individual hand-authored shadow sprites would
  duplicate work across assets and miss runtime-created objects. A shared
  alpha-mask shader and source-following proxy handle both authored and dynamic
  sprites.
- **Mirrored obstacle layer:** obstacle tiles have no reusable `Sprite2D`
  source node, and can be destroyed or edited at runtime. A non-colliding
  mirrored tile layer uses the existing atlas art and follows those edits
  without changing collision maps or tile mutation callers.
- **Keep rendering separate from gameplay lookup:** the earlier experiment
  added a shadow sibling before a tilemap in `BackTileMap`. At that time,
  `get_background_tilemap()` descended through children by numeric index. The
  extra sibling changed the child order, so the method returned the wrong
  tilemap. Since `Player` treats cells missing from that map as void, players
  fell and died. The current implementation uses the stable named path and
  attaches tile shadows beneath their owning obstacle maps instead of
  inserting nodes into the background hierarchy.

The player nodes themselves are also moved within `World`'s child list during
falling and respawn. This is another reason the gameplay tilemap reference must
not depend on sibling position.
