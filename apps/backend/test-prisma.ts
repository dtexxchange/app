import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const txs = await prisma.transaction.findMany({
    take: 1,
    include: {
        user: { select: { email: true, firstName: true, lastName: true, readableId: true } },
        logs: { orderBy: { createdAt: 'asc' } },
    }
  });
  console.log(JSON.stringify(txs, null, 2));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
