# Guia para modificar overlays en Tabletop Simulator

Este documento resume el metodo correcto para modificar overlays del save `TS_Save_4.json` sin volver a ajustar a ciegas.

## Idea clave

Los overlays no se comportan como rectangulos editables lado por lado.

En TTS estamos modificando objetos con:

- Un objeto plantilla oculto.
- Uno o varios `ChildObjects`.
- Un mesh `.obj` con su propio pivote.
- Transformaciones heredadas del objeto padre/clon.
- Escala y rotacion aplicadas por Lua al hacer spawn.

Por eso cambiar `posZ` o `scaleX` en el JSON no equivale directamente a "mover este borde" o "hacer crecer hacia dentro".

La forma segura es trabajar con medidas ingame reales y ajustar por iteracion controlada.

## Capas de transformacion

En el caso de `Deployment Zones` visible:

- Boton visible: `bd190b`
- Tecla 3: plantilla `7b966f`
- Nombre de plantilla: `Horizontal Deployment`
- Child azul: `bb88df`
- Child rojo: `37cead`

El script global hace spawn de la plantilla y luego aplica:

```lua
OVERLAY_SPAWN_X = 34.12
OVERLAY_SPAWN_Y = 0.89
overlayTypeZ["deployment"] = 5.32
OVERLAY_SCALE = {x = 0.896, y = 0.6, z = 0.797}
OVERLAY_ROT = {x = 0, y = 0, z = 180.0}
```

Eso significa que los `Transform` internos de `bb88df` y `37cead` no son coordenadas finales de mesa. Son coordenadas locales dentro de una plantilla que luego se clona, escala y rota.

## Regla practica

No intentes deducir todo de cabeza.

Para cambios de tamano/posicion:

1. Crea ingame un objeto volumetrico de referencia con la forma exacta que quieres.
2. Lee su `Position` y `Scale` desde el Transform de TTS.
3. Modifica el overlay.
4. Spawnea el overlay real.
5. Lee el `Position` y `Scale` reales generados por el overlay.
6. Compara objetivo vs resultado.
7. Ajusta solo la variable que corresponde.

## Que significa cada desfase

Si el `Scale` ingame del overlay no coincide:

- Hay que tocar escala interna del child.
- En el overlay de franjas horizontales, el grosor visible en Z depende de `scaleX`.
- El largo visible en X depende de `scaleZ`.

Si el `Position` ingame no coincide, pero el `Scale` si coincide:

- No toques escala.
- Corrige solo posicion (`posX` / `posZ`) del child.

## Caso resuelto: Deployment Zones tipo 3

Objetivo creado con objeto volumetrico:

Lado azul:

```text
Position {4.92, 1.41, 10.49}
Scale    {44.57, 1.00, 4.46}
```

Lado rojo:

```text
Position {4.98, 1.41, -10.30}
Scale    {44.57, 1.00, 4.46}
```

Valores finales correctos en la plantilla `7b966f`:

Child azul `bb88df`:

```json
"Transform": {
  "posX": 32.667411,
  "posZ": -6.009528,
  "scaleX": 87.889274,
  "scaleZ": 65.279926
}
```

Child rojo `37cead`:

```json
"Transform": {
  "posX": 32.678571,
  "posZ": -7.102141,
  "scaleX": 87.889274,
  "scaleZ": 65.279926
}
```

Notas:

- `scaleX` controla el ancho/grosor visible de la franja.
- `scaleZ` controla el largo de la franja.
- `posZ` no debe interpretarse como Z final de mesa.
- La escala final correcta se confirmo ingame como `Scale {44.57, 1.00, 4.46}`.

## Metodo de ajuste recomendado

### 1. Primero igualar escala

Si el objetivo es:

```text
Scale objetivo {44.57, 1.00, 4.46}
```

y el overlay generado mide:

```text
Scale real {44.57, 1.00, 2.15}
```

entonces el largo X ya esta bien y solo falla el grosor Z.

En ese caso:

```text
factor = grosor_objetivo / grosor_real
factor = 4.46 / 2.15
```

Multiplica `scaleX` del child por ese factor.

No cambies `posZ` en este paso.

### 2. Despues igualar posicion

Cuando la escala ya coincida, mide el `Position` real ingame.

Ejemplo real:

```text
Rojo objetivo: Position {4.98, 1.41, -10.30}
Rojo real:     Position {5.02, 1.41, -5.21}
```

Aqui la escala ya estaba bien, asi que solo habia que corregir posicion.

No tocar `scaleX` ni `scaleZ`.

### 3. Evitar ajustes acumulativos sin medir

No hagas esto:

- "crece 1 pulgada hacia dentro"
- tocar `scaleX`
- tocar `posZ`
- volver a tocar ambos sin medir el resultado

Eso acumula errores porque el pivote del mesh no esta centrado y hay rotaciones heredadas.

Haz esto:

- Cambiar una cosa.
- Medir ingame.
- Comparar.
- Corregir solo el eje que falla.

## Como detectar que se esta tocando la plantilla equivocada

El save contiene dos botones de Deployment:

```lua
["bd190b"] = {
    [2] = "eaa9a7",
    [3] = "7b966f",
}

["a2056b"] = {
    [2] = "bdcfc7",
    [3] = "4aa032",
}
```

El visible es `bd190b`.

Por tanto, para `Deployment Zones` visible:

- Tecla 2: editar `eaa9a7`
- Tecla 3: editar `7b966f`

No editar `4aa032` si se quiere cambiar el boton visible.

## Checklist antes de tocar un overlay

- Identificar el boton visible.
- Confirmar en `overlayTemplates` que GUID de plantilla usa esa tecla.
- Confirmar los `ChildObjects` internos.
- Medir objetivo ingame con un objeto volumetrico.
- Cambiar primero escala.
- Spawnear y medir escala real.
- Cambiar despues posicion.
- Spawnear y medir posicion real.
- Guardar los valores finales en este documento si quedan bien.

## Advertencia importante

No asumir que:

```text
child.posZ == position Z ingame
```

Eso es falso para estos overlays.

La posicion ingame resulta de:

```text
posicion child
+ pivote/offset del mesh
+ rotacion child
+ escala child
+ posicion padre clon
+ escala padre clon
+ rotacion padre clon
```

Por eso la fuente de verdad para cambios visuales debe ser siempre la medicion ingame final.

## Nuevo enfoque: meshes centrados

Cuando un overlay hereda offsets enormes del mod original 1v1, no conviene seguir escalando el mesh viejo.

Mejor:

- Crear un `.obj` local nuevo.
- Poner el pivote del mesh en el centro real del tablero.
- Usar coordenadas locales X/Z iguales a unidades TTS.
- Spawnear el overlay en el centro real del tablero.
- Usar `scale {1,1,1}` para que los vertices del `.obj` sean directamente editables.

### Territory 2v2 diagonal

Territory tipo 2 se rehizo con meshes locales en:

```text
overlay_meshes/territory2_blue.obj
overlay_meshes/territory2_red.obj
```

Centro de spawn:

```text
X = 4.99
Z = 0.07
```

Escala:

```lua
[2] = {x = 1.0, y = 1.0, z = 1.0}
```

La diagonal correcta de 2v2 no va de esquina a esquina del rectangulo total. Va desde:

```text
(-11.1425,  7.48) local al centro del tablero
( 11.1425, -7.48) local al centro del tablero
```

Esto equivale a:

- punto medio del lado corto superior del tablero izquierdo
- punto medio del lado corto inferior del tablero derecho

Con este enfoque, para cambiar Territory 2 solo hay que editar vertices de los `.obj`:

```obj
v X 0.000000 Z
```

No hay que volver a pelearse con offsets del boton ni con pivotes fuera del tablero.
