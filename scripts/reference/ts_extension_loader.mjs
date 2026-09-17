/**
 * Node 24 type-stripping loader for mingyu's extensionless local TS imports.
 * Only retries relative/absolute imports with `.ts` or `/index.ts`.
 */
export async function resolve(specifier, context, nextResolve) {
  try {
    return await nextResolve(specifier, context);
  } catch (error) {
    const local = specifier.startsWith('.') || specifier.startsWith('/') || specifier.startsWith('file:');
    const hasExtension = /\.[a-z0-9]+$/i.test(specifier);
    if (!local || hasExtension) throw error;

    for (const suffix of ['.ts', '/index.ts']) {
      try {
        return await nextResolve(`${specifier}${suffix}`, context);
      } catch (_) {
        // Try the next local TypeScript form.
      }
    }
    throw error;
  }
}
