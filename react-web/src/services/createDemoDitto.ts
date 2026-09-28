import { Authenticator, Ditto, DittoConfig } from '@dittolive/ditto'

export async function createDemoDitto(): Promise<Ditto> {
  const databaseID = import.meta.env.VITE_DEMO_DITTO_DATABASE_ID?.trim() ?? ''
  const serverURL = import.meta.env.VITE_DEMO_DITTO_SERVER_URL?.trim() ?? ''
  const playgroundToken =
    import.meta.env.VITE_DEMO_DITTO_PLAYGROUND_TOKEN?.trim() ?? ''

  if (!databaseID || !serverURL || !playgroundToken) {
    throw new Error(
      [
        'Missing demo Ditto Web credentials.',
        'Set VITE_DEMO_DITTO_DATABASE_ID, VITE_DEMO_DITTO_SERVER_URL,',
        'and VITE_DEMO_DITTO_PLAYGROUND_TOKEN in a local .env file.',
      ].join(' '),
    )
  }

  const ditto = await Ditto.open(
    new DittoConfig(
      databaseID,
      { mode: 'server', url: serverURL },
      'react-web-match-tracker',
    ),
  )

  await ditto.auth.setExpirationHandler(async (expiringDitto) => {
    await expiringDitto.auth.login(
      playgroundToken,
      Authenticator.DEVELOPMENT_PROVIDER,
    )
  })

  ditto.sync.start()
  return ditto
}
