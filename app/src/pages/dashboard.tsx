import { useState, useEffect } from 'react'
import Head from 'next/head'
import styles from '@/styles/Dashboard.module.css'

type LinkStats = {
  slug: string
  url: string
  title: string | null
  totalClicks: number
  createdAt: string
}

export default function Dashboard() {
  const [links, setLinks] = useState<LinkStats[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // In a real app this would call GET /api/links with pagination
    // For the skeleton, we show a mock list to demonstrate the UI
    setTimeout(() => {
      setLinks([
        { slug: 'gh4r2x', url: 'https://github.com/your-username/snipurl', title: 'SnipURL repo', totalClicks: 142, createdAt: new Date().toISOString() },
        { slug: 'az9k1m', url: 'https://portal.azure.com/#view/network', title: 'Azure Networking', totalClicks: 87, createdAt: new Date().toISOString() },
        { slug: 'tf2p8q', url: 'https://developer.hashicorp.com/terraform/docs', title: 'Terraform docs', totalClicks: 54, createdAt: new Date().toISOString() },
      ])
      setLoading(false)
    }, 600)
  }, [])

  return (
    <>
      <Head>
        <title>Dashboard — SnipURL</title>
        <link href="https://fonts.googleapis.com/css2?family=Syne:wght@600;700;800&family=DM+Mono:wght@300;400;500&display=swap" rel="stylesheet" />
      </Head>

      <div className={styles.page}>
        <div className={styles.grid} aria-hidden />

        <header className={styles.header}>
          <a href="/" className={styles.logo}>snip<span>url</span></a>
          <h1 className={styles.title}>Dashboard</h1>
        </header>

        <main className={styles.main}>
          {/* Stats summary */}
          <div className={styles.statsRow}>
            {[
              { label: 'Total links', value: links.length },
              { label: 'Total clicks', value: links.reduce((s, l) => s + l.totalClicks, 0) },
              { label: 'Region', value: 'East US' },
              { label: 'Network', value: 'Hub-Spoke' },
            ].map(stat => (
              <div key={stat.label} className={styles.statCard}>
                <div className={styles.statValue}>{loading ? '—' : stat.value}</div>
                <div className={styles.statLabel}>{stat.label}</div>
              </div>
            ))}
          </div>

          {/* Links table */}
          <div className={styles.tableWrapper}>
            <div className={styles.tableHeader}>
              <span>Recent links</span>
            </div>

            {loading ? (
              <div className={styles.loading}>Loading…</div>
            ) : (
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th>Slug</th>
                    <th>Destination</th>
                    <th>Title</th>
                    <th>Clicks</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {links.map(link => (
                    <tr key={link.slug}>
                      <td>
                        <a href={`/${link.slug}`} className={styles.slugCell} target="_blank" rel="noreferrer">
                          /{link.slug}
                        </a>
                      </td>
                      <td className={styles.urlCell}>
                        {link.url.slice(0, 50)}{link.url.length > 50 ? '…' : ''}
                      </td>
                      <td className={styles.titleCell}>{link.title ?? '—'}</td>
                      <td className={styles.clicksCell}>{link.totalClicks.toLocaleString()}</td>
                      <td>
                        <a href={`/api/links/${link.slug}/stats`} className={styles.actionLink} target="_blank" rel="noreferrer">
                          Stats →
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </main>
      </div>
    </>
  )
}
