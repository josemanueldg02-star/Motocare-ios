// Tests de las reglas de seguridad de Firestore para MotoCare.
//
// Se ejecutan contra el Firebase Emulator (sin tocar producción) mediante:
//     npm test      (desde la carpeta firebase/)
//
// Cada test describe un escenario de ataque o de uso legítimo y comprueba
// que las reglas lo permiten o lo bloquean como corresponde.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { before, after, beforeEach, test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, Timestamp } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(join(here, '..', 'firestore.rules'), 'utf8');

let testEnv;

// Perfil válido de ejemplo, tal y como lo escribe AuthService.swift.
function validUser(uid, overrides = {}) {
  return {
    uid,
    name: 'Jose Manuel',
    email: 'jose@example.com',
    phoneNumber: null,
    createdAt: Timestamp.now(),
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-motocare',
    firestore: { rules },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('users/{uid}', () => {
  const ALICE = 'alice-uid';
  const BOB = 'bob-uid';

  test('el dueño puede crear su propio perfil válido', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(setDoc(doc(db, 'users', ALICE), validUser(ALICE)));
  });

  test('el dueño puede leer su propio perfil', async () => {
    // Sembramos el dato saltándonos las reglas.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE), validUser(ALICE));
    });
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(getDoc(doc(db, 'users', ALICE)));
  });

  test('un usuario NO puede leer el perfil de otro', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', BOB), validUser(BOB));
    });
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(getDoc(doc(db, 'users', BOB)));
  });

  test('un usuario NO puede escribir en el perfil de otro', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(setDoc(doc(db, 'users', BOB), validUser(BOB)));
  });

  test('un usuario sin autenticar NO puede leer ni escribir', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE), validUser(ALICE));
    });
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'users', ALICE)));
    await assertFails(setDoc(doc(anon, 'users', ALICE), validUser(ALICE)));
  });

  test('NO se puede crear un perfil con un uid suplantado (uid != id del doc)', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    // Alice intenta escribir en su doc pero poniendo el uid de Bob dentro.
    await assertFails(setDoc(doc(db, 'users', ALICE), validUser(BOB)));
  });

  test('NO se puede crear un perfil con campos mal formados (createdAt no es timestamp)', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(doc(db, 'users', ALICE), validUser(ALICE, { createdAt: 'ayer' }))
    );
  });

  test('NO se puede crear un perfil con un nombre absurdamente largo', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(doc(db, 'users', ALICE), validUser(ALICE, { name: 'x'.repeat(101) }))
    );
  });

  test('en una actualización el uid es inmutable', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE), validUser(ALICE));
    });
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertFails(
      setDoc(doc(db, 'users', ALICE), validUser(ALICE, { uid: 'otro-uid' }))
    );
  });

  test('el dueño puede borrar su propio perfil', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', ALICE), validUser(ALICE));
    });
    const db = testEnv.authenticatedContext(ALICE).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'users', ALICE)));
  });
});

describe('otras colecciones', () => {
  test('cualquier colección fuera de users está denegada, incluso autenticado', async () => {
    const db = testEnv.authenticatedContext('alice-uid').firestore();
    await assertFails(getDoc(doc(db, 'garages', 'alice-uid')));
    await assertFails(setDoc(doc(db, 'garages', 'alice-uid'), { foo: 'bar' }));
    await assertFails(setDoc(doc(db, 'secretos', 'x'), { foo: 'bar' }));
  });
});
