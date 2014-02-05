// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/// A [MapTypeMask] is a [TypeMask] for a specific allocation
/// site of a map (currently only internal Map class) that will get specialized
/// once the [TypeGraphInferrer] phase finds a key and/or value type for it.
class MapTypeMask extends ForwardingTypeMask {
  final TypeMask forwardTo;

  // The [Node] where this type mask was created.
  final Node allocationNode;

  // The [Element] where this type mask was created.
  final Element allocationElement;

  // The value type of this map.
  final TypeMask valueType;

  // The key type of this map.
  final TypeMask keyType;

  MapTypeMask(this.forwardTo,
              this.allocationNode,
              this.allocationElement,
              this.keyType,
              this.valueType);

  TypeMask nullable() {
    return isNullable
        ? this
        : new MapTypeMask(forwardTo.nullable(),
                          allocationNode,
                          allocationElement,
                          keyType,
                          valueType);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new MapTypeMask(forwardTo.nonNullable(),
                          allocationNode,
                          allocationElement,
                          keyType,
                          valueType)
        : this;
  }

  bool get isContainer => false;
  bool get isMap => true;
  bool get isExact => true;

  bool equalsDisregardNull(other) {
    if (other is! MapTypeMask) return false;
    return allocationNode == other.allocationNode
        && keyType == other.keyType
        && valueType == other.valueType;
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    TypeMask forwardIntersection = forwardTo.intersection(other, compiler);
    if (forwardIntersection.isEmpty) return forwardIntersection;
    return forwardIntersection.isNullable
        ? nullable()
        : nonNullable();
  }

  TypeMask union(other, Compiler compiler) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmpty) {
      return other.isNullable ? this.nullable() : this;
    } else if (other.isMap
               && keyType != null
               && other.keyType != null
               && valueType != null
               && other.valueType != null) {
      TypeMask newKeyType =
          keyType.union(other.keyType, compiler);
      TypeMask newValueType =
          valueType.union(other.valueType, compiler);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, compiler);
      return new MapTypeMask(
          newForwardTo, null, null, newKeyType, newValueType);
    } else {
      return forwardTo.union(other, compiler);
    }
  }

  bool operator==(other) {
    if (other is! MapTypeMask) return false;
    return allocationNode == other.allocationNode
        && isNullable == other.isNullable
        && keyType == other.keyType
        && valueType == other.valueType
        && forwardTo == other.forwardTo;
  }

  int get hashCode {
    return computeHashCode(
        allocationNode, isNullable, keyType, valueType, forwardTo);
  }

  String toString() {
    return 'Map mask: [$keyType/$valueType] type: $forwardTo';
  }
}
