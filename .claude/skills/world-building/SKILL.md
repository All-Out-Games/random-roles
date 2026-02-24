---
name: world-building
description: You MUST reference this before placing, arranging, or decorating anything in the scene
---

# World Building
### Step 1: Orient — Understand what exists

Before touching anything, get your bearings.

```
scene_hierarchy          → See all entities and structure
scene_camera (get)       → Know where the viewport is looking
scene_screenshot         → See the current scene visually
```

**Always start here.** You need to know what's already placed, what assets are available locally, and what the scene looks like before making any changes.

### Step 2: Plan — Break down the request
- **What elements are needed?** ("forest with a road" → road surface, trees, bushes, grass, maybe rocks)
- **What's the spatial layout?** (road goes from A to B, trees line both sides, fill behind with denser forest)
- **What layers/depth?** (ground first, then objects on top, decorations last)
- **What assets do I need?** (list every distinct visual element)

### Step 3: Discover assets — Local first, catalog second

**This order is critical. Always exhaust local assets before searching the catalog.**

#### 3a. Search local relevant assets
```
assets_find (query: "tree")
assets_find (query: "road")
assets_find (query: "grass")
```

#### 3b. Search catalog only for any gaps
```
catalog_search (query: "oak tree")
catalog_search (query: "dirt road tile")
```

#### 3c. Download what you need
```
catalog_download (source_url: "...", filename: "environment/oak_tree.png")
```

### Step 4: Build — Place entities in logical order

Build from the ground up: **background → ground → large features → small details → decorations.**

For backgrounds and ground textures, make sure to set them to layer -10 so the player is on top. Most other things should be at layer 0 (default)

After each major step, orient the camera and then **call `scene_screenshot`** to see the current viewport. Fix any issues before proceeding. If an asset doesn't look right, delete it and find another one.

#### Placing assets — use `instantiate_asset`

**This is the fastest way to place things.** It automatically creates the right entity type based on the asset (Sprite_Renderer for textures, full prefab instantiation for prefabs, Spine_Animator for spine rigs).

**Call `scene_screenshot`** after each item you add. Inspect the result and swap assets until they look great together. Only after the composition is cohesive, proceed with further placement. 

```
instantiate_asset (asset_id: "environment/tree.png", position: [5, 3], name: "Tree_1", scale: [1.2, 1.2])
instantiate_asset (asset_id: "environment/road.png", position: [0, 0], name: "Road_Segment_1")
instantiate_asset (asset_id: "environment/bush.png", position: [-2, 1], scale: [-1, 1])  // flipped horizontally
```

The response includes `visual_size: [w, h]` — the entity's world-space dimensions accounting for texture size, pixels-per-unit, and scale. Use this to plan layouts.

#### Relative positioning — tiling and grids

Place entities edge-to-edge relative to an existing entity. The tool calculates exact positions using both entities' visual sizes so sprites tile perfectly with no overlap or gaps.

```
// Place road segments in a row
instantiate_asset (asset_id: "environment/road.png", position: [0, 0], name: "Road_1")
instantiate_asset (asset_id: "environment/road.png", relative_to: "Road_1", direction: "right", name: "Road_2")
instantiate_asset (asset_id: "environment/road.png", relative_to: "Road_2", direction: "right", name: "Road_3")

// Stack blocks vertically
instantiate_asset (asset_id: "props/crate.png", position: [0, 0], name: "Crate_1")
instantiate_asset (asset_id: "props/crate.png", relative_to: "Crate_1", direction: "above", name: "Crate_2")
```

Parameters:
- `relative_to` — name of the anchor entity to position relative to
- `direction` — `"right"`, `"left"`, `"above"`, or `"below"`
- `gap` — extra spacing in world units between the edges (default 0). Use for grids with consistent spacing.

```
// Trees with 1.5 unit gaps between them
instantiate_asset (asset_id: "nature/tree.png", position: [0, 0], name: "Tree_1")
instantiate_asset (asset_id: "nature/tree.png", relative_to: "Tree_1", direction: "right", gap: 1.5, name: "Tree_2")
instantiate_asset (asset_id: "nature/tree.png", relative_to: "Tree_2", direction: "right", gap: 1.5, name: "Tree_3")
```

When `relative_to` is used, the `position` parameter should be ommitted. 

Use `instantiate_asset` for straightforward placement. Use `modify_scene` when you need to do complex operations in one batch (parenting, adding extra components, setting Sprite_Renderer properties like layer/tint).

#### Batch operations with `modify_scene`

For setting layers, tint, depth, or doing multiple complex ops at once:
```json
{
  "operations": [
    {
      "kind": "set_component_properties",
      "entity_name": "Tree_1",
      "component_type": "Sprite_Renderer",
      "properties": { "layer": 5 }
    },
    {
      "kind": "set_parent",
      "entity_name": "Tree_1",
      "parent_name": "Forest_Left"
    }
  ]
}
```

#### Key fields on Sprite_Renderer
- `texture` — asset path (what you'd pass to `assets_find`)
- `layer` — integer draw order. Higher layers render on top. Use this to separate ground (-10), objects (0), foreground (8+)
- `tint` — `[r, g, b, a]` values 0-1. Use for color variation (e.g. slightly different greens on trees)

#### Naming conventions
Name entities descriptively so they're easy to find and modify later:
- `Road_Segment_1`, `Road_Segment_2` (not `Entity_1`)
- `Tree_Large_Left_1`, `Tree_Small_Right_3`
- `Bush_Cluster_A`, `Grass_Patch_2`

#### Use parenting for organization
Create empty parent entities to group related objects:
```json
{
  "operations": [
    {"kind": "create_entity", "name": "Forest_Left"},
    {"kind": "create_entity", "name": "Tree_1", "parent_name": "Forest_Left", "position": [-5, 3], ...},
    {"kind": "create_entity", "name": "Tree_2", "parent_name": "Forest_Left", "position": [-4, 5], ...}
  ]
}
```

### Step 5: Verify — Look at what you built

After each batch of changes:

```
scene_camera (focus_area, min: [-10, -5], max: [10, 5])   → Frame the area you just built
scene_screenshot                                            → See the result
```

**Always screenshot after placing things.** You cannot judge the result without seeing it. Check for:
- Gaps or overlaps that look wrong
- Scale issues (something too big or too small)
- Layer ordering problems (ground rendering over trees)

### Step 6: Iterate — Fix and polish

Based on what you see in the screenshot:

- **Adjust transforms** with `set_transform` operations
- **Fix layering** with `set_component_properties` on the Sprite_Renderer
- **Add variety** — vary scale slightly (`[0.9, 0.9]` to `[1.3, 1.3]`), flip sprites with negative scale (`[-1, 1]`), tint with subtle color shifts
- **Fill gaps** — add smaller detail entities (grass, flowers, rocks) between the big pieces

## Tips for Beautiful Scenes

### Variety is everything
Never place the same asset at the same scale in a row. For organic environments:
- Use 2-3 different tree/bush assets if available
- Randomize scale: 0.8 to 1.4 range
- Flip some sprites horizontally with negative X scale: `[-1, 1]`
- Rotate slightly if the asset supports it
- Tint subtly: e.g. `[0.9, 1.0, 0.85, 1]` for slightly warmer green

### Depth and layering
- Ground/terrain: layers -10
- Ground details (grass, flowers, pebbles): layer 0
- Foreground overlaps: layers 10

### Spatial distribution
- Organic things (trees, rocks) should NOT be on a grid — offset positions irregularly
- Cluster things in groups of 2-4 rather than spacing evenly
- Leave breathing room — not every gap needs filling
- Dense at edges, sparser toward points of interest (the road, a clearing)
