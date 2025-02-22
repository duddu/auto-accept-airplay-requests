import dotenv from '@dotenvx/dotenvx'

const metadataKeys = [
  'AAR_BUILD_NUMBER',
  'AAR_BUNDLE_DISPLAY_NAME',
  'AAR_BUNDLE_NAME',
  'AAR_DOCS_URL',
  'AAR_REPO_URL',
  'AAR_VERSION',
] as const

type MapWithConstKeys<T extends Readonly<string[]>> = Readonly<{
  [K in T[number]]: string
}>

type Metadata = MapWithConstKeys<typeof metadataKeys>

const getMetadata = (): Metadata => {
  const metadata = {} as Metadata

  dotenv.config({
    overload: true,
    override: true,
    strict: true,
    path: ['../Config.xcconfig'],
    processEnv: metadata,
  })

  Object.freeze(metadata)

  const unboundVar = metadataKeys.find(key =>
    typeof metadata[key] !== 'string' || metadata[key].trim() === '')
  if (typeof unboundVar !== 'undefined') {
    throw new ReferenceError(
      `No valid value configured for ${unboundVar} ` +
      `(${JSON.stringify(metadata[unboundVar])}).\n\n` +
      `Dotenv config output: ${JSON.stringify(metadata, null, 3)}\n`
    )
  }

  return metadata
}

export default getMetadata()
