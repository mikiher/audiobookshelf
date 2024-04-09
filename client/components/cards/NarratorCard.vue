<template>
  <div>
    <nuxt-link :to="`/library/${currentLibraryId}/bookshelf?filter=narrators.${$encode(narrator.name)}`">
      <div :style="{ width: cardWidth + 'px', height: cardHeight + 'px', fontSize: sizeMultiplier + 'rem' }" class="bg-primary box-shadow-book rounded-md relative overflow-hidden">
        <div class="absolute inset-0 w-full h-full flex items-center justify-center pointer-events-none opacity-40">
          <span class="material-icons-outlined text-[10em]">record_voice_over</span>
        </div>

        <!-- Narrator name & num books overlay -->
        <div class="absolute bottom-0 left-0 w-full py-1 bg-black bg-opacity-60 px-2">
          <p class="text-center font-semibold truncate" :style="{ fontSize: 0.75 + 'em' }">{{ name }}</p>
          <p class="text-center text-gray-200" :style="{ fontSize: 0.65 + 'em' }">{{ numBooks }} Book{{ numBooks === 1 ? '' : 's' }}</p>
        </div>
      </div>
    </nuxt-link>
  </div>
</template>

<script>
export default {
  props: {
    narrator: {
      type: Object,
      default: () => {}
    },
    width: Number,
    height: Number
  },
  data() {
    return {}
  },
  computed: {
    cardWidth() {
      return this.width || this.cardHeight * 1.5
    },
    cardHeight() {
      return this.height || 100 * this.sizeMultiplier
    },
    name() {
      return this.narrator?.name || ''
    },
    numBooks() {
      return this.narrator?.numBooks || this.narrator?.books?.length || 0
    },
    userCanUpdate() {
      return this.$store.getters['user/getUserCanUpdate']
    },
    currentLibraryId() {
      return this.$store.state.libraries.currentLibraryId
    },
    sizeMultiplier() {
      return this.$store.getters['user/getSizeMultiplier']
    }
  },
  methods: {}
}
</script>