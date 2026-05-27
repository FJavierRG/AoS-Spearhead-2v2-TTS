# Problema técnico: callbacks de teclas numéricas sobre Custom_Model en TTS

## ✅ SOLUCIONADO

**Causa**: la propiedad `max_typed_number` del objeto es `0` por defecto, lo que hace que TTS NO procese las teclas numéricas sobre él. Hay que configurarla explícitamente al cargar el objeto.

**Fix**: añadir esto al script LOCAL de cada botón (en su `onLoad`):

```lua
function onLoad()
    self.max_typed_number = 3
end

function onNumberTyped(player_color, number)
    -- handler aquí, return true para bloquear comportamiento por defecto
end
```

Con `max_typed_number = 3`, TTS empieza a escuchar pulsaciones numéricas (1, 2, 3) mientras se hace hover sobre el botón, y dispara `onNumberTyped` localmente. No se necesita el callback global `onObjectNumberTyped` si se hace por scripts locales.

Si se quisiera usar el callback global, sigue haciendo falta `self.max_typed_number = 3` en cada objeto que debe responder.

---

## Resumen ejecutivo

Estamos modificando el mod **Age of Sigmar Spearhead** en Tabletop Simulator para crear una versión 2v2 (doble tablero unido por el lado largo). El problema actual: **al pulsar las teclas numéricas 1/2/3 con el ratón sobre los botones físicos de los overlays** (Territory, Terrain Zones, Deployment Zones, Board Edges), no se dispara ningún callback Lua, ni global ni local.

Lo demás funciona: `onLoad`, `onChat` (con comandos custom), `spawnObject`/`clone` para crear overlays, etc.

---

## Contexto del mod

### Estructura original (1v1)

El mod tiene 7 objetos `Custom_Model` que actúan como **botones de overlay**:
- 2× Territory (`a5109b` Fire&Jade, `9b180a` Sand&Bone)
- 2× Terrain Zones (`9fe02b`, `4a1317`)
- 2× Deployment Zones (`bd190b`, `a2056b`)
- 1× Board Edges (`abb564`)

Cada botón tiene **States internos** (2/3 según el caso) que son meshes con triángulos/áreas semitransparentes que se proyectan sobre el tablero. El usuario pulsa 1/2/3 con el ratón sobre el botón y TTS hace `setState` nativo, mostrando el mesh correspondiente.

El truco del autor original es que el **offset interno del mesh del state** está calculado para que con el origen del botón en `x=19.5, z=offset_z` y `scale=0.6`, el área visible quede centrada sobre el tablero (`x=0, z=0`). Es decir, **la posición del overlay está acoplada a la posición del botón mediante un offset hardcoded en el archivo del mesh `.obj`**.

### Lo que cambia en 2v2

Hay dos tableros unidos por el lado largo:
- Tile 1 (original): `(16.2, 0.81, 0)`, scale `(11.2, 1, 11.2)`, rotY 90°.
- Tile 2 (clon): `(-6.2, 0.81, 0)`, mismo scale/rot.
- Como `Custom_Tile Type=0 Box` con `Stretch=True` interpreta `scale` como **radio**, cada tile mide `22.4 × 22.4`.
- Conjunto resultante: `x ∈ (-17.4, 27.4)` (ancho 44.8) × `z ∈ (-11.2, 11.2)` (ancho 22.4), centrado en `(5, 0)`.

Los overlays originales (mesh 22.4×22.4 centrado en x=0) **solo cubren la mitad del conjunto**.

### Por qué no podemos simplemente reescalar y reposicionar el state

Empíricamente comprobamos que TTS al hacer `setState` nativo:
- **Conserva la posición actual del objeto padre**, ignorando la `posX` guardada en el state interno.
- **Sí usa la `scaleX` del state interno**.

Resultado: si duplicas `scaleX` del state para que el área cubra 44.8 en X, el offset interno del mesh también se escala. El centro del mesh queda en `posX_padre + (-19.5/0.6) × scaleX = posX_padre - 39`, lejos del centro deseado `x=5`.

### Refactor que decidimos hacer (Opción A)

Para desacoplar el botón del overlay:

1. **Extraer los States internos** como objetos plantilla independientes, ocultos en `y=-1000` (las plantillas siguen existiendo como objetos sueltos, sin formar parte de los States del botón).
2. **Vaciar los States del botón padre**: queda como botón puro sin states.
3. **Capturar las pulsaciones 1/2/3** sobre el botón mediante callback Lua y **clonar la plantilla** con `template.clone({position={x=44, y=0.89, z=...}})`, aplicando luego `setScale({1.2, 0.6, 0.6})` para cubrir el conjunto entero. La posición `x=44` compensa el offset interno escalado (`44 - 39 = 5` = centro del conjunto).

Esta mecánica **funciona** cuando se invoca desde un comando de chat (`onChat("spawn")` → `_spawnOverlay(...)`), pero **no se dispara automáticamente al pulsar 1/2/3 sobre el botón**.

---

## El problema concreto

### Comportamiento esperado

Cuando el usuario sitúa el ratón sobre el botón `a5109b` ("Territory") y pulsa la tecla `2`, TTS debe llamar a uno de los siguientes callbacks:

- **Global script**: `onObjectNumberTyped(obj, player_color, number, alt)` (callback global, debería dispararse para cualquier objeto).
- **Object script**: `onNumberTyped(player_color, number)` (callback local, debería dispararse para el objeto que tiene el script).

Cualquiera de los dos serviría para nuestro propósito.

### Comportamiento observado

Probado AMBOS callbacks (consecutivamente y juntos):

- **Global** `onObjectNumberTyped` en el `LuaScript` raíz del save: **no se dispara**.
- **Local** `onNumberTyped` en el `LuaScript` del propio botón: **no se dispara**.

No aparece ni un solo `print()`, `broadcastToAll()` ni callback ejecutado al pulsar 1/2/3 sobre los botones. Sí aparecen los broadcasts de `onLoad` y `onChat` con normalidad.

### Verificaciones realizadas

- ✅ El Global script se carga: aparece `broadcastToAll("==> Global script CARGADO OK!")` desde `onLoad()`.
- ✅ `onChat(message, player)` funciona: comandos custom como `test`, `spawn`, `despawn`, `hide`, `showbtn` ejecutan correctamente.
- ✅ Los 7 botones existen en escena con sus GUIDs correctos (verificado vía comando `showbtn` que itera la tabla y comprueba `getObjectFromGUID`).
- ✅ La función `_spawnOverlay(button_guid, state_num)` funciona y crea el overlay clonado en la posición deseada cuando se invoca desde `onChat`.
- ✅ El script LOCAL del botón está bien guardado en el JSON (verificado releyendo el `LuaScript` del objeto, 305 chars cada uno).
- ❌ Ningún callback de pulsación de tecla se ejecuta.

### Cosas probadas que no resolvieron

1. **Mover el callback de Object script a Global script** (y viceversa). Ninguno de los dos se dispara.
2. **Desbloquear el objeto** (`Locked = False`). Sin cambios.
3. **Recrear los botones con nuevos GUIDs** para forzar a TTS a re-evaluar los scripts desde cero.
4. **Recargar el save** completamente (cerrar/abrir).

---

## Características del objeto botón

Extracto del JSON de uno de los botones (`a5109b`, "Territory"):

```json
{
  "GUID": "a5109b",
  "Name": "Custom_Model",
  "Transform": { "posX": 31.5, "posY": 0.89, "posZ": 12.0,
                 "rotX": 0, "rotY": 0, "rotZ": 180,
                 "scaleX": 0.6, "scaleY": 0.6, "scaleZ": 0.6 },
  "Nickname": "Territory",
  "Locked": true,
  "Grid": true,
  "Snap": true,
  "Tooltip": true,
  "CustomMesh": {
    "MeshURL": "https://steamusercontent-a.akamaihd.net/.../335DEC...",
    "DiffuseURL": "https://steamusercontent-a.akamaihd.net/.../999A4...",
    "ColliderURL": "https://steamusercontent-a.akamaihd.net/.../18BA2A...",
    "Convex": true, "MaterialIndex": 1, "TypeIndex": 1
  },
  "LuaScript": "function onLoad() ... end\nfunction onNumberTyped(player_color, number) ... end",
  "States": {}                                   ← antes tenía {2: {...}, 3: {...}}, vaciado por el refactor
}
```

Después del refactor:
- `States` es `{}` (vacío). Antes contenía los meshes de Diagonal/Horizontal Territory.
- `LuaScript` contiene el callback local `onNumberTyped`.
- Las plantillas (antes `States`) ahora son objetos sueltos en `ObjectStates` en `y=-1000`.

---

## Hipótesis posibles

1. **¿Es obligatorio que `Custom_Model` tenga `States` definidos para que TTS dispare callbacks de tecla numérica sobre él?**
   La doc de TTS (https://api.tabletopsimulator.com/events/) dice que `onObjectNumberTyped` "is called when a player types a number whilst hovering over an object", sin indicar restricciones. Pero podría ser que internamente TTS solo enrute las teclas numéricas a objetos que tengan `States` o sean cards/decks.

2. **¿Necesita la propiedad `max_typed_number` configurada explícitamente?**
   La doc menciona `max_typed_number` como "el máximo de dígitos que un usuario puede escribir mientras hace hover". Por defecto puede ser 0, lo que quizá impide que se procesen teclas.

3. **¿Necesita `interactable: true` explícito + sin `Locked`?**
   El objeto tiene `Locked: true` (heredado del mod original) e `interactable` por defecto. Probamos desbloquear sin éxito.

4. **¿TTS requiere `function onLoad()` definida para que se carguen los demás callbacks locales?**
   Cada botón tiene su `onLoad` definido. Verificado que se ejecuta (broadcast).

5. **¿Conflicto con otros scripts que consumen el evento antes?**
   Es posible que algún otro objeto (deck, scoresheet) en la escena tenga su propio `onObjectNumberTyped` que retorne `true` y bloquee el resto.

---

## Información adicional del save

- Versión del juego/mod: TTS, mod base "Age of Sigmar Spearhead" (Steam Workshop), Spearhead 2v2 modificado por nosotros.
- Save file: `TS_Save_4.json` (~11 MB, 130K líneas tras refactor).
- Global script (`LuaScript` en raíz): contiene `onLoad`, `onChat`, `onObjectNumberTyped` (global), tablas `overlayButtons`, `overlayTemplates`, `overlayTypeZ`, `_spawnOverlay`, `_despawnOverlay`, `_handleOverlayInput`, `_hideOverlayTemplates`.
- Scripts locales: cada botón tiene `LuaScript` con `onLoad` (broadcast) + `onNumberTyped` que llama a `Global.call("_handleOverlayInput", {...})`.

---

## Cómo reproducir

1. Cargar `TS_Save_4.json` en TTS.
2. Esperar a ver el mensaje broadcast "==> Global script CARGADO OK!" y 7 mensajes `[boton-onLoad] ... cargado!`.
3. Pasar el ratón sobre el botón "Territory" (visible a la derecha del tablero combinado, a `x≈31.5, z≈12`).
4. Pulsar la tecla `2`.

**Esperado**: aparecen broadcasts `[boton] Tecla 2 sobre Territory` y se spawnea el overlay sobre el tablero.

**Observado**: no pasa absolutamente nada.

Como contraste, abrir el chat (Enter) y escribir `spawn`. El mismo `_spawnOverlay("a5109b", 2)` SÍ se ejecuta y crea correctamente el overlay sobre el tablero. La mecánica funciona; lo que falla es el callback de entrada de tecla.

---

## Pregunta concreta a la ingeniería

> ¿Por qué los callbacks `onObjectNumberTyped` (Global) y `onNumberTyped` (Object) no se disparan al pulsar teclas numéricas sobre un `Custom_Model` que carece de `States` internos pero tiene `LuaScript` válido (con `onLoad` que sí se ejecuta)? ¿Qué propiedad del objeto debe configurarse para que TTS enrute las pulsaciones numéricas hacia él?

Cualquier alternativa funcional para detectar pulsaciones de tecla específicas sobre estos botones (sin recurrir a botones UI clickables) sería igualmente válida.
