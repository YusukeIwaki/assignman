# ユースケース設計書

このドキュメントでは、assignmanアプリケーションの主要なユースケースについて説明します。

## アサインメント関連ユースケース

### 1. CreateDetailedProjectAssignmentFromRoughProjectAssignment（管理者用）

**目的**: 管理者が粗い計画（RoughProjectAssignment）から詳細な確定アサイン（DetailedProjectAssignment）を作成する

**アクター**: Admin（管理者）

**前提条件**:
- 管理者が組織に属していること
- 対象のRoughProjectAssignmentが存在すること

**処理内容**:
1. 管理者の権限チェック（同一組織かどうか）
2. メンバーの容量制約チェック
3. RoughProjectAssignmentからDetailedProjectAssignmentを作成
4. 元のRoughProjectAssignmentを削除

**成功条件**: DetailedProjectAssignmentが正常に作成され、RoughProjectAssignmentが削除される

**例外処理**:
- 権限がない場合: AuthorizationError
- 容量制約に違反する場合: ValidationError
- 必須パラメータが不足している場合: ValidationError

### 2. AcknowledgeDetailedProjectAssignment（メンバー用）

**目的**: メンバーが自分に割り当てられた詳細アサイン（DetailedProjectAssignment）を確認・承認する

**アクター**: Member（メンバー）

**前提条件**:
- メンバーが組織に属していること
- 対象のDetailedProjectAssignmentが存在すること
- アサインメントがそのメンバー自身のものであること

**処理内容**:
1. メンバーの権限チェック（自分のアサインメントかどうか）
2. 組織レベルの整合性チェック
3. 確認処理（現在は単純にSuccessを返す、将来的には承認ステータスの更新を予定）

**成功条件**: アサインメントの確認が正常に完了する

**例外処理**:
- 他人のアサインメントを確認しようとした場合: AuthorizationError
- 異なる組織のメンバーの場合: ValidationError
- 必須パラメータが不足している場合: ValidationError

## ユースケース間の関係

```
RoughProjectAssignment ──[CreateDetailedProjectAssignmentFromRoughProjectAssignment]──> DetailedProjectAssignment
                                                                                                      │
                                                                                                      ▼
                                                                                   [AcknowledgeDetailedProjectAssignment]
                                                                                                      │
                                                                                                      ▼
                                                                                               確認・承認済み
```

## 設計原則

1. **単一責任の原則**: 各ユースケースは一つの明確な責任を持つ
2. **権限分離**: 管理者とメンバーで異なる権限体系
3. **ドメイン駆動設計**: ビジネスロジックをドメインモデルに適切に配置
4. **明確なネーミング**: ユースケース名が実際の処理内容を正確に表現

## 将来の拡張予定

- **AcknowledgeDetailedProjectAssignment**: 承認ステータスの永続化
- **RejectDetailedProjectAssignment**: メンバーによるアサインメント拒否機能
- **ModifyDetailedProjectAssignment**: 管理者による確定後のアサインメント変更機能