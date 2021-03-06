class Openfst < Formula
  homepage "http://www.openfst.org/"
  url "https://openfst.org/twiki/pub/FST/FstDownload/openfst-1.4.1.tar.gz"
  sha256 "e671bf6bd4425a1fed4e7543a024201b74869bfdd029bdf9d10c53a3c2818277"
  patch :p0, :DATA

  needs :cxx11

  def install

    ENV.cxx11

    system "./configure", "--prefix=#{prefix}",
           "--disable-dependency-tracking",
           "--enable-compact-fsts",
           "--enable-compress",
           "--enable-const-fsts",
           "--enable-far",
           "--enable-linear-fsts",
           "--enable-lookahead-fsts",
           "--enable-mpdt",
           "--enable-ngram-fsts",
           "--enable-pdt",
           "--enable-static",
           "--enable-shared"
    system "make", "install"
  end

  test do
    # Based on http://openfst.org/twiki/bin/view/FST/FstExamples.
    # Makes symbol table.
    File.open("ascii.syms", "w") do |sink|
      sink.puts "<epsilon>\t0"
      sink.puts "<space>\t32"
      33.upto(126) { |i| sink.puts "#{i.chr}\t#{i}" }
    end
    # Makes arclist for downcasing FST.
    File.open("downcase.arc", "w") do |sink|
      sink.puts "0\t0\t<epsilon>\t<epsilon>"
      sink.puts "0\t0\t<space>\t<space>"
      33.upto(126) { |i| sink.puts "0\t0\t#{i.chr}\t#{i.chr.downcase}" }
      sink.puts "0"
    end
    ## Compile the machine
    system bin/"fstcompile", "--isymbols=ascii.syms",
           "--osymbols=ascii.syms",
           "downcase.arc",
           "downcase.fst"
  end
end
__END__
*** src/include/fst/minimize.h
***************
*** 134,140 ****
    typedef typename A::Weight Weight;
    typedef ReverseArc<A> RevA;

!   CyclicMinimizer(const ExpandedFst<A>& fst) {
      Initialize(fst);
      Compute(fst);
    }
--- 134,147 ----
    typedef typename A::Weight Weight;
    typedef ReverseArc<A> RevA;

!   CyclicMinimizer(const ExpandedFst<A>& fst):
!       // tell the Partition data-member to expect multiple repeated
!       // calls to SplitOn with the same element if we are non-deterministic.
!       P_(fst.Properties(kIDeterministic, true) == 0) {
!     if(fst.Properties(kIDeterministic, true) == 0)
!       CHECK(Weight::Properties() & kIdempotent); // this minimization
!     // algorithm for non-deterministic FSTs can only work with idempotent
!     // semirings.
      Initialize(fst);
      Compute(fst);
    }
***************
*** 315,321 ****
    typedef typename A::StateId ClassId;
    typedef typename A::Weight Weight;

!   AcyclicMinimizer(const ExpandedFst<A>& fst) {
      Initialize(fst);
      Refine(fst);
    }
--- 322,334 ----
    typedef typename A::StateId ClassId;
    typedef typename A::Weight Weight;

!   AcyclicMinimizer(const ExpandedFst<A>& fst):
!       // tell the Partition data-member to expect multiple repeated
!       // calls to SplitOn with the same element if we are non-deterministic.
!       partition_(fst.Properties(kIDeterministic, true) == 0) {
!     if(fst.Properties(kIDeterministic, true) == 0)
!       CHECK(Weight::Properties() & kIdempotent); // minimization for
!     // non-deterministic FSTs can only work with idempotent semirings.
      Initialize(fst);
      Refine(fst);
    }
***************
*** 531,543 ****
  void Minimize(MutableFst<A>* fst,
                MutableFst<A>* sfst = 0,
                float delta = kDelta) {
!   uint64 props = fst->Properties(kAcceptor | kIDeterministic|
!                                  kWeighted | kUnweighted, true);
!   if (!(props & kIDeterministic)) {
!     FSTERROR() << "FST is not deterministic";
!     fst->SetProperties(kError, kError);
!     return;
!   }

    if (!(props & kAcceptor)) {  // weighted transducer
      VectorFst< GallicArc<A, STRING_LEFT> > gfst;
--- 544,550 ----
  void Minimize(MutableFst<A>* fst,
                MutableFst<A>* sfst = 0,
                float delta = kDelta) {
!   uint64 props = fst->Properties(kAcceptor | kWeighted | kUnweighted, true);

    if (!(props & kAcceptor)) {  // weighted transducer
      VectorFst< GallicArc<A, STRING_LEFT> > gfst;
*** src/include/fst/partition.h
***************
*** 43,50 ****
    friend class PartitionIterator<T>;

    struct Element {
!    Element() : value(0), next(0), prev(0) {}
!    Element(T v) : value(v), next(0), prev(0) {}

     T        value;
     Element* next;
--- 43,50 ----
    friend class PartitionIterator<T>;

    struct Element {
!     Element() : value(0), next(0), prev(0) {}
!     Element(T v) : value(v), next(0), prev(0) {}

     T        value;
     Element* next;
***************
*** 52,60 ****
    };

   public:
!   Partition() {}

!   Partition(T num_states) {
      Initialize(num_states);
    }

--- 52,62 ----
    };

   public:
!   Partition(bool allow_repeated_split):
!       allow_repeated_split_(allow_repeated_split) {}

!   Partition(bool allow_repeated_split, T num_states):
!       allow_repeated_split_(allow_repeated_split) {
      Initialize(num_states);
    }

***************
*** 137,152 ****
      if (class_size_[class_id] == 1) return;

      // first time class is split
!     if (split_size_[class_id] == 0)
        visited_classes_.push_back(class_id);
!
      // increment size of split (set of element at head of chain)
      split_size_[class_id]++;
!
      // update split point
!     if (class_split_[class_id] == 0)
!       class_split_[class_id] = classes_[class_id];
!     if (class_split_[class_id] == elements_[element_id])
        class_split_[class_id] = elements_[element_id]->next;

      // move to head of chain in same class
--- 139,154 ----
      if (class_size_[class_id] == 1) return;

      // first time class is split
!     if (split_size_[class_id] == 0) {
        visited_classes_.push_back(class_id);
!       class_split_[class_id] = classes_[class_id];
!     }
      // increment size of split (set of element at head of chain)
      split_size_[class_id]++;
!
      // update split point
!     if (class_split_[class_id] != 0
!         && class_split_[class_id] == elements_[element_id])
        class_split_[class_id] = elements_[element_id]->next;

      // move to head of chain in same class
***************
*** 157,180 ****
    // class indices of the newly created class. Returns the new_class id
    // or -1 if no new class was created.
    T SplitRefine(T class_id) {
      // only split if necessary
!     if (class_size_[class_id] == split_size_[class_id]) {
!       class_split_[class_id] = 0;
        split_size_[class_id] = 0;
        return -1;
      } else {
-
        T new_class = AddClass();
        size_t remainder = class_size_[class_id] - split_size_[class_id];
        if (remainder < split_size_[class_id]) {  // add smaller
-         Element* split_el   = class_split_[class_id];
          classes_[new_class] = split_el;
-         class_size_[class_id] = split_size_[class_id];
-         class_size_[new_class] = remainder;
          split_el->prev->next = 0;
          split_el->prev = 0;
        } else {
-         Element* split_el   = class_split_[class_id];
          classes_[new_class] = classes_[class_id];
          class_size_[class_id] = remainder;
          class_size_[new_class] = split_size_[class_id];
--- 159,189 ----
    // class indices of the newly created class. Returns the new_class id
    // or -1 if no new class was created.
    T SplitRefine(T class_id) {
+
+     Element* split_el = class_split_[class_id];
      // only split if necessary
!     //if (class_size_[class_id] == split_size_[class_id]) {
!     if(split_el == NULL) { // we split on everything...
        split_size_[class_id] = 0;
        return -1;
      } else {
        T new_class = AddClass();
+
+       if(allow_repeated_split_) { // split_size_ is possibly
+         // inaccurate, so work it out exactly.
+         size_t split_count;  Element *e;
+         for(split_count=0,e=classes_[class_id];
+             e != split_el; split_count++, e=e->next);
+         split_size_[class_id] = split_count;
+       }
        size_t remainder = class_size_[class_id] - split_size_[class_id];
        if (remainder < split_size_[class_id]) {  // add smaller
          classes_[new_class] = split_el;
          split_el->prev->next = 0;
          split_el->prev = 0;
+         class_size_[class_id] = split_size_[class_id];
+         class_size_[new_class] = remainder;
        } else {
          classes_[new_class] = classes_[class_id];
          class_size_[class_id] = remainder;
          class_size_[new_class] = split_size_[class_id];
***************
*** 245,254 ****
--- 254,269 ----
    vector<T> class_size_;

    // size of split for each class
+   // in the nondeterministic case, split_size_ is actually an upper
+   // bound on the size of split for each class.
    vector<T> split_size_;

    // set of visited classes to be used in split refine
    vector<T> visited_classes_;
+
+   // true if input fst was deterministic: we can make
+   // certain assumptions in this case that speed up the algorithm.
+   bool allow_repeated_split_;
  };
