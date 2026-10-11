import { copyFileSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { deflateSync } from 'node:zlib'

const iosRoot = join(dirname(fileURLToPath(import.meta.url)), '..')
const appRoot = join(iosRoot, '..', 'app')
const output = join(iosRoot, 'Stretchly', 'Generated')

const catalogInfo = { author: 'xcode', version: 1 }

const writeJSON = (path, data) => writeFileSync(path, JSON.stringify(data, null, 2) + '\n')

const syncLocales = () => {
  const target = join(output, 'Locales')
  mkdirSync(target, { recursive: true })
  readdirSync(join(appRoot, 'locales'))
    .filter(file => file.endsWith('.json'))
    .forEach(file => copyFileSync(join(appRoot, 'locales', file), join(target, file)))

  const preferences = readFileSync(join(appRoot, 'preferences.html'), 'utf8')
  const select = preferences.match(/<select name="language" id="language">([\s\S]*?)<\/select>/)
  if (!select) throw new Error('Language list not found in preferences.html')
  const languages = [...select[1].matchAll(/<option value="([^"]+)">([^<]+)<\/option>/g)]
    .map(([, code, name]) => ({ code, name: name.trim() }))
  writeJSON(join(target, 'languages.json'), languages)
}

const syncFonts = () => {
  const target = join(output, 'Fonts')
  mkdirSync(target, { recursive: true })
  for (const font of ['NotoSans-Light.ttf', 'NotoSans-Regular.ttf']) {
    copyFileSync(join(appRoot, 'css', 'fonts', font), join(target, font))
  }
}

const syncSounds = () => {
  const target = join(output, 'Sounds')
  mkdirSync(target, { recursive: true })
  readdirSync(join(appRoot, 'audio'))
    .filter(file => file.endsWith('.wav') && file !== 'silence.wav')
    .forEach(file => copyFileSync(join(appRoot, 'audio', file), join(target, file)))
}

const cleanSVG = (path) => {
  const source = readFileSync(path, 'utf8')
  const viewBox = source.match(/viewBox="([^"]+)"/)[1]
  const paths = (source.match(/<path\b[^>]*>/g) || [])
    .map(element => element.replace(/currentColor/g, '#000000').replace(/\s+/g, ' ').replace(/\s*\/?>$/, ' />'))
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">\n${paths.join('\n')}\n</svg>\n`
}

const imageSet = (catalog, name, images, properties = {}) => {
  const target = join(catalog, `${name}.imageset`)
  mkdirSync(target, { recursive: true })
  const entries = images.map(({ file, contents, dark }) => {
    const filename = dark ? `${name}-dark${file.slice(file.lastIndexOf('.'))}` : `${name}${file.slice(file.lastIndexOf('.'))}`
    if (contents) {
      writeFileSync(join(target, filename), contents)
    } else {
      copyFileSync(file, join(target, filename))
    }
    const entry = { filename, idiom: 'universal' }
    if (dark) entry.appearances = [{ appearance: 'luminosity', value: 'dark' }]
    return entry
  })
  writeJSON(join(target, 'Contents.json'), { images: entries, info: catalogInfo, properties })
}

const syncImages = () => {
  const catalog = join(output, 'Shared.xcassets')
  mkdirSync(catalog, { recursive: true })
  writeJSON(join(catalog, 'Contents.json'), { info: catalogInfo })

  const images = join(appRoot, 'images')
  const vector = { 'preserves-vector-representation': true }
  const template = { ...vector, 'template-rendering-intent': 'template' }

  for (const name of ['break-postpone', 'break-skip', 'break-finish']) {
    imageSet(catalog, name, [{ file: `${name}.svg`, contents: cleanSVG(join(images, 'breaks', `${name}.svg`)) }], template)
  }
  for (const name of ['settings', 'schedule', 'theme', 'about', 'heart']) {
    imageSet(catalog, `nav-${name}`, [{ file: join(images, 'preferences', `${name}.svg`) }], vector)
  }
  imageSet(catalog, 'logo', [
    { file: join(images, 'stretchly.svg') },
    { file: join(images, 'stretchly-dark.svg'), dark: true }
  ], vector)
  imageSet(catalog, 'home', [
    { file: join(images, 'preferences', 'home.svg') },
    { file: join(images, 'preferences', 'home-dark.svg'), dark: true }
  ], vector)
  imageSet(catalog, 'speaker', [
    { file: join(images, 'preferences', 'speaker.png') },
    { file: join(images, 'preferences', 'speaker-dark.png'), dark: true }
  ])

  const launch = join(catalog, 'LaunchBackground.colorset')
  mkdirSync(launch, { recursive: true })
  const color = (hex) => {
    const [red, green, blue] = hexToRGB(hex).map(value => (value / 255).toFixed(3))
    return { 'color-space': 'srgb', components: { red, green, blue, alpha: '1.000' } }
  }
  writeJSON(join(launch, 'Contents.json'), {
    colors: [
      { idiom: 'universal', color: color('#EDEDED') },
      { idiom: 'universal', appearances: [{ appearance: 'luminosity', value: 'dark' }], color: color('#2D2D2D') }
    ],
    info: catalogInfo
  })

  const appIcon = join(catalog, 'AppIcon.appiconset')
  mkdirSync(appIcon, { recursive: true })
  writeFileSync(join(appIcon, 'icon-1024.png'), renderAppIcon(join(images, 'stretchly.svg'), 1024))
  writeJSON(join(appIcon, 'Contents.json'), {
    images: [{ filename: 'icon-1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }],
    info: catalogInfo
  })
}

const parsePath = (d) => {
  const tokens = d.match(/[a-zA-Z]|-?\d*\.?\d+(?:e[-+]?\d+)?/g)
  const polygons = []
  let polygon = []
  let x = 0
  let y = 0
  let command = ''
  let index = 0
  const number = () => parseFloat(tokens[index++])
  while (index < tokens.length) {
    if (/[a-zA-Z]/.test(tokens[index])) command = tokens[index++]
    const relative = command === command.toLowerCase()
    const ox = relative ? x : 0
    const oy = relative ? y : 0
    switch (command.toUpperCase()) {
      case 'M':
        if (polygon.length) polygons.push(polygon)
        x = ox + number()
        y = oy + number()
        polygon = [[x, y]]
        command = relative ? 'l' : 'L'
        break
      case 'L':
        x = ox + number()
        y = oy + number()
        polygon.push([x, y])
        break
      case 'H':
        x = ox + number()
        polygon.push([x, y])
        break
      case 'V':
        y = oy + number()
        polygon.push([x, y])
        break
      case 'C': {
        const c1 = [ox + number(), oy + number()]
        const c2 = [ox + number(), oy + number()]
        const end = [ox + number(), oy + number()]
        for (let step = 1; step <= 24; step++) {
          const t = step / 24
          const u = 1 - t
          polygon.push([
            u * u * u * x + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t * t * t * end[0],
            u * u * u * y + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t * t * t * end[1]
          ])
        }
        x = end[0]
        y = end[1]
        break
      }
      case 'Z':
        if (polygon.length) {
          polygons.push(polygon)
          x = polygon[0][0]
          y = polygon[0][1]
        }
        polygon = []
        break
      default:
        throw new Error(`Unsupported path command '${command}' in logo`)
    }
  }
  if (polygon.length) polygons.push(polygon)
  return polygons
}

const hexToRGB = (hex) => [1, 3, 5].map(offset => parseInt(hex.slice(offset, offset + 2), 16))

const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1
  return c >>> 0
})

const crc32 = (buffer) => {
  let crc = 0xFFFFFFFF
  for (const byte of buffer) crc = crcTable[(crc ^ byte) & 0xFF] ^ (crc >>> 8)
  return (crc ^ 0xFFFFFFFF) >>> 0
}

const chunk = (type, data) => {
  const length = Buffer.alloc(4)
  length.writeUInt32BE(data.length)
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data])
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(body))
  return Buffer.concat([length, body, crc])
}

const encodePNG = (pixels, size) => {
  const header = Buffer.alloc(13)
  header.writeUInt32BE(size, 0)
  header.writeUInt32BE(size, 4)
  header.set([8, 2, 0, 0, 0], 8)
  const raw = Buffer.alloc((size * 3 + 1) * size)
  for (let row = 0; row < size; row++) {
    for (let column = 0; column < size * 3; column++) {
      raw[row * (size * 3 + 1) + 1 + column] = Math.round(pixels[row * size * 3 + column])
    }
  }
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    chunk('IHDR', header),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0))
  ])
}

const renderAppIcon = (svgPath, size) => {
  const source = readFileSync(svgPath, 'utf8')
  const shapes = [...source.matchAll(/<path d="([^"]+)"[^>]*fill="(#[0-9A-Fa-f]{6})"/g)]
    .map(([, d, fill]) => ({ polygons: parsePath(d), color: hexToRGB(fill) }))
  const points = shapes.flatMap(shape => shape.polygons.flat())
  const minX = Math.min(...points.map(p => p[0]))
  const maxX = Math.max(...points.map(p => p[0]))
  const minY = Math.min(...points.map(p => p[1]))
  const maxY = Math.max(...points.map(p => p[1]))
  const scale = size * 0.6 / Math.max(maxX - minX, maxY - minY)
  const offsetX = (size - (maxX - minX) * scale) / 2 - minX * scale
  const offsetY = (size - (maxY - minY) * scale) / 2 - minY * scale

  const background = hexToRGB('#F7F7F7')
  const pixels = new Float32Array(size * size * 3)
  for (let i = 0; i < size * size; i++) pixels.set(background, i * 3)

  const samples = 4
  for (const shape of shapes) {
    const coverage = new Float32Array(size * size)
    const edges = shape.polygons.flatMap(polygon => polygon.map((point, i) => {
      const nextPoint = polygon[(i + 1) % polygon.length]
      return [point[0] * scale + offsetX, point[1] * scale + offsetY, nextPoint[0] * scale + offsetX, nextPoint[1] * scale + offsetY]
    }))
    for (let sub = 0; sub < size * samples; sub++) {
      const y = (sub + 0.5) / samples
      const row = Math.floor(y)
      const crossings = edges
        .filter(([, y0, , y1]) => (y0 <= y && y1 > y) || (y1 <= y && y0 > y))
        .map(([x0, y0, x1, y1]) => [x0 + (y - y0) * (x1 - x0) / (y1 - y0), y1 > y0 ? 1 : -1])
        .sort((a, b) => a[0] - b[0])
      let winding = 0
      let spanStart = 0
      for (const [x, direction] of crossings) {
        const previous = winding
        winding += direction
        if (previous === 0 && winding !== 0) spanStart = x
        if (previous !== 0 && winding === 0) {
          const from = Math.max(0, spanStart)
          const to = Math.min(size, x)
          for (let column = Math.floor(from); column < Math.ceil(to); column++) {
            const overlap = Math.min(to, column + 1) - Math.max(from, column)
            if (overlap > 0) coverage[row * size + column] += overlap / samples
          }
        }
      }
    }
    for (let i = 0; i < size * size; i++) {
      const alpha = Math.min(1, coverage[i])
      if (alpha === 0) continue
      for (let channel = 0; channel < 3; channel++) {
        pixels[i * 3 + channel] = pixels[i * 3 + channel] * (1 - alpha) + shape.color[channel] * alpha
      }
    }
  }
  return encodePNG(pixels, size)
}

rmSync(output, { recursive: true, force: true })
mkdirSync(output, { recursive: true })
syncLocales()
syncFonts()
syncSounds()
syncImages()
console.log(`Stretchly: synced shared resources into ${output}`)
