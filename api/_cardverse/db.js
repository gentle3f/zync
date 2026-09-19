let clientPromise;

function databaseUrl() {
  const raw = (process.env.DATABASE_URL || '').trim();
  if (!/^postgres(?:ql)?:\/\//i.test(raw)) {
    const error = new Error('cardverse_database_not_configured');
    error.code = 'cardverse_database_not_configured';
    throw error;
  }
  return raw;
}

function sslOption() {
  const mode = (process.env.CARDVERSE_DATABASE_SSL || '').trim().toLowerCase();
  if (mode === 'disable') return false;
  return 'require';
}

export function cardverseDatabaseConfigured() {
  return /^postgres(?:ql)?:\/\//i.test((process.env.DATABASE_URL || '').trim());
}

export async function getCardverseDatabase() {
  if (!clientPromise) {
    clientPromise = import('postgres').then(({ default: postgres }) => {
      const sql = postgres(databaseUrl(), {
        max: 1,
        prepare: false,
        ssl: sslOption(),
        connect_timeout: 10,
        idle_timeout: 20,
        max_lifetime: 60 * 5,
      });

      const wrap = (client) => ({
        query(text, params = []) {
          return client.unsafe(text, params);
        },
      });

      return {
        ...wrap(sql),
        transaction(callback) {
          return sql.begin(async (tx) => callback(wrap(tx)));
        },
        close() {
          return sql.end({ timeout: 5 });
        },
      };
    });
  }
  return clientPromise;
}

export async function closeCardverseDatabase() {
  if (!clientPromise) return;
  const db = await clientPromise;
  clientPromise = undefined;
  await db.close();
}
