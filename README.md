# commands-nt

Sistema de Punição para servidores FiveM construído sobre o framework vRP, com persistência em banco de dados. Aplica um "modo punição" em jogadores que descumprem regras, bloqueando ações ofensivas (atirar, mirar, drive-by) por um tempo determinado, com aplicação e remoção via comandos administrativos.

## Funcionalidades

- Bloqueio de tiro, mira e drive-by enquanto a punição estiver ativa
- Comandos `/punir` e `/despunir` restritos a grupo administrativo
- **Persistência em banco de dados** — punição sobrevive a reconexão e restart do servidor
- Tempo de punição configurável com auto-remoção via timer no servidor
- Reaplicação automática do tempo restante quando o jogador volta online
- Auto-cleanup de punições expiradas que terminaram durante o offline
- Sistema de tokens evita race conditions em reconexões
- State replicado (`Punishment-nt`) para outros resources detectarem o status do jogador
- Auditoria: registra quem aplicou, quando aplicou, e quando termina

## Dependências

- [vRP](https://github.com/vRP-framework/vRP) — framework base
- MySQL — para persistência das punições
- Sistema de notificação compatível com o evento `Notify` (cliente e servidor)

## Instalação

1. Coloque a pasta `commands-nt` em `resources/` do seu servidor
2. Execute o `database.sql` no banco de dados do seu servidor
3. Adicione `ensure commands-nt` no `server.cfg`
4. Reinicie o servidor

## Configuração

No arquivo `server-side/core.lua`:

```lua
local Config = {
    AdminGroup = "Admin",  -- grupo necessário para usar os comandos
    DefaultTime = 600,     -- tempo padrão em segundos (10 min)
    MaxTime = 3600,        -- tempo máximo permitido (1 hora)
}
```

## Uso

| Comando     | Argumentos        | Descrição                                  |
|-------------|-------------------|--------------------------------------------|
| `/punir`    | `[id] [tempo?]`   | Aplica modo punição no jogador             |
| `/despunir` | `[id]`            | Remove o modo punição manualmente          |

Se `tempo` não for informado, usa `DefaultTime`. Tempos acima de `MaxTime` são truncados automaticamente.

**Exemplo:**
```
/punir 12 300       -- pune o jogador de id 12 por 5 minutos
/despunir 12        -- libera antes do tempo acabar
```

## Estrutura

```
commands-nt/
├── fxmanifest.lua
├── database.sql
├── client-side/
│   └── core.lua
└── server-side/
    └── core.lua
```

## Schema do banco de dados

```sql
CREATE TABLE IF NOT EXISTS `nt_punishments` (
    `passport` INT(11) NOT NULL,
    `end_time` INT(11) NOT NULL,
    `applied_by` INT(11) DEFAULT NULL,
    `applied_at` INT(11) NOT NULL,
    PRIMARY KEY (`passport`),
    INDEX `idx_end_time` (`end_time`)
);
```

`passport` como PK garante que cada player tem no máximo uma punição ativa. O índice em `end_time` permite consultas eficientes para futuras rotinas de limpeza ou relatórios.

## Como funciona

**Client-side:** Ao receber o evento `nt_punishment:Init`, ativa um loop com `Wait(0)` que chama `DisableControlAction` em cada frame para os IDs de controle de ataque e mira — chamada por frame é exigência da engine pra que o bloqueio tenha efeito. `PlayerId()` e o tamanho da tabela de controles bloqueados são cacheados fora do loop pra evitar overhead. A flag local `IsPunished` controla a vida da thread e protege contra triggers duplicados. Após carregar, o cliente chama `CheckPunishment` no servidor pra reaplicar punições ativas vindas do banco.

**Server-side:** Os comandos validam o grupo do solicitante via `vRP.HasGroup`, conferem se o alvo existe, e gravam a punição na tabela `nt_punishments` com `INSERT ... ON DUPLICATE KEY UPDATE`. A função `ApplyPunishment` agenda um `SetTimeout` para auto-despunição usando um sistema de tokens — cada timer recebe um ID único, e antes de executar o cleanup verifica se ainda é o "timer vivo" pra aquela punição. Isso evita race conditions quando o player reconecta e um novo timer é criado: o antigo dispara, vê que seu token não bate mais, e desiste silenciosamente.

**Fluxo de reconexão:**
1. Player é punido, registro vai pro DB com `end_time`
2. Player desconecta no meio da punição
3. Player reconecta, cliente chama `CheckPunishment`
4. Servidor consulta DB, calcula tempo restante, e reaplica a punição
5. Se a punição já expirou enquanto o player estava offline, o registro é limpo do DB e nada é aplicado

## Autor

natti9202
