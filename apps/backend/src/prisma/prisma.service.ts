import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const adapter = new PrismaPg(pool);
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
    await this.initializeSequences();
  }

  private async initializeSequences() {
    try {
      const seqResult = await this.$queryRawUnsafe<{ seq_name: string }[]>(
        `SELECT pg_get_serial_sequence('"Transaction"', 'readableId') AS seq_name`
      );
      if (seqResult && seqResult.length > 0 && seqResult[0].seq_name) {
        const seqName = seqResult[0].seq_name;
        const result = await this.$queryRawUnsafe<{ last_value: string; is_called: boolean }[]>(
          `SELECT last_value, is_called FROM ${seqName}`
        );
        if (result && result.length > 0) {
          const lastValue = Number(result[0].last_value);
          const isCalled = result[0].is_called;
          // If the sequence value is small (e.g. less than 100,000) and it has not been advanced or is just starting
          if (lastValue < 100000 && (!isCalled || lastValue <= 1)) {
            const randomStart = Math.floor(100000 + Math.random() * 900000);
            await this.$executeRawUnsafe(
              `ALTER SEQUENCE ${seqName} RESTART WITH ${randomStart}`
            );
            console.log(`[PrismaService] Restarted sequence ${seqName} with random start: ${randomStart}`);
          }
        }
      }
    } catch (error) {
      console.error('[PrismaService] Error initializing sequence:', error);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
