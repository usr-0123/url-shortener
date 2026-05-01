import { useState, useRef } from 'react'
import Head from 'next/head'
import styles from '@/styles/Home.module.css'

type Result = {
  shortUrl: string
  slug: string
  url: string
}

export default function Home() {
  const [url, setUrl] = useState('')
  const [customSlug, setCustomSlug] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<Result | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setResult(null)
    setLoading(true)

    try {
      const res = await fetch('/api/links', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url, slug: customSlug || undefined }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? 'Something went wrong')
        return
      }

      setResult(data)
      setUrl('')
      setCustomSlug('')
    } catch {
      setError('Network error — please try again')
    } finally {
      setLoading(false)
    }
  }

  async function handleCopy() {
    if (!result) return
    await navigator.clipboard.writeText(result.shortUrl)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <>
      <Head>
        <title>SnipURL — Sharpen your links</title>
        <meta name="description" content="Fast, private URL shortener deployed on Azure hub-spoke network" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Mono:wght@300;400;500&display=swap" rel="stylesheet" />
      </Head>

      <div className={styles.page}>
        {/* Background grid */}
        <div className={styles.grid} aria-hidden />

        {/* Top bar */}
        <header className={styles.header}>
          <span className={styles.logo}>snip<span className={styles.logoAccent}>url</span></span>
          <nav className={styles.nav}>
            <a href="/dashboard" className={styles.navLink}>Dashboard</a>
            <a href="https://github.com/YOUR_USERNAME/snipurl" className={styles.navLink} target="_blank" rel="noreferrer">
              GitHub ↗
            </a>
          </nav>
        </header>

        {/* Hero */}
        <main className={styles.main}>
          <div className={styles.hero}>
            <div className={styles.badge}>
              <span className={styles.badgeDot} />
              Running on Azure · East US
            </div>

            <h1 className={styles.headline}>
              Sharpen<br />your links.
            </h1>

            <p className={styles.subheadline}>
              Deployed on a private Azure hub-spoke network.<br />
              Zero public endpoints. One Terraform command.
            </p>
          </div>

          {/* Form */}
          <form className={styles.form} onSubmit={handleSubmit}>
            <div className={styles.inputRow}>
              <input
                ref={inputRef}
                type="url"
                className={styles.input}
                placeholder="https://your-very-long-url.com/goes/here"
                value={url}
                onChange={e => setUrl(e.target.value)}
                required
                autoFocus
              />
              <button
                type="submit"
                className={styles.button}
                disabled={loading || !url}
              >
                {loading ? <span className={styles.spinner} /> : 'Snip →'}
              </button>
            </div>

            {/* Custom slug toggle */}
            <div className={styles.optionRow}>
              <span className={styles.optionLabel}>Custom slug</span>
              <div className={styles.slugInput}>
                <span className={styles.slugPrefix}>snipurl.io/</span>
                <input
                  type="text"
                  className={styles.slugField}
                  placeholder="my-link"
                  value={customSlug}
                  onChange={e => setCustomSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ''))}
                  maxLength={12}
                />
              </div>
            </div>

            {error && (
              <div className={styles.error} role="alert">
                ⚠ {error}
              </div>
            )}
          </form>

          {/* Result card */}
          {result && (
            <div className={styles.resultCard}>
              <div className={styles.resultInner}>
                <div className={styles.resultMeta}>
                  <span className={styles.resultCheck}>✓</span>
                  <span className={styles.resultLabel}>Link created</span>
                </div>
                <div className={styles.resultUrl}>{result.shortUrl}</div>
                <div className={styles.resultOriginal}>→ {result.url.slice(0, 60)}{result.url.length > 60 ? '…' : ''}</div>
              </div>
              <div className={styles.resultActions}>
                <button className={styles.copyButton} onClick={handleCopy}>
                  {copied ? '✓ Copied' : 'Copy'}
                </button>
                <a
                  className={styles.statsLink}
                  href={`/api/links/${result.slug}/stats`}
                  target="_blank"
                  rel="noreferrer"
                >
                  Stats →
                </a>
              </div>
            </div>
          )}
        </main>

        {/* Footer */}
        <footer className={styles.footer}>
          <span>Built with Next.js + Terraform on Azure</span>
          <span className={styles.footerDivider}>·</span>
          <span>Hub-Spoke VNet · Azure Firewall · Traffic Manager</span>
        </footer>
      </div>
    </>
  )
}
