import 'dotenv/config';
import { PrismaClient, Role, UserStatus } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 Seeding database...');

  // 1. Seed Admin User
  const adminEmail = process.env.SEED_ADMIN_EMAIL || 'admin@equinoxexchange.com';
  const admin = await prisma.user.upsert({
    where: { email: adminEmail.toLowerCase() },
    update: {
      role: Role.ADMIN,
      status: UserStatus.APPROVED,
    },
    create: {
      email: adminEmail.toLowerCase(),
      firstName: 'Super',
      lastName: 'Admin',
      role: Role.ADMIN,
      status: UserStatus.APPROVED,
      balance: 0.0,
      referralCode: '',
    },
  });
  console.log(`✅ Admin user ready: ${admin.email} (ID: ${admin.id}, Role: ${admin.role})`);

  console.log('✨ Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
