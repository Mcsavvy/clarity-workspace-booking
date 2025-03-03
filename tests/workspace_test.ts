import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test workspace management and booking with payments",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Add a workspace
      Tx.contractCall('workspace', 'add-workspace', [
        types.uint(1),
        types.uint(4),
        types.uint(100)
      ], deployer.address),
      
      // Book the workspace with payment
      Tx.contractCall('workspace', 'book-workspace', [
        types.uint(1),
        types.uint(20240815)
      ], user1.address),
      
      // Try booking invalid date
      Tx.contractCall('workspace', 'book-workspace', [
        types.uint(1),
        types.uint(20220815)
      ], user1.address),
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectErr(types.uint(106)); // err-invalid-date
  },
});
